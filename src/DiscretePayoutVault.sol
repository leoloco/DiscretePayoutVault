// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {ERC4626} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

import {UsdToken} from "./UsdToken.sol";

/// @title DiscretePayoutVault
/// @notice A vault that distributes proceeds fairly to users based on share ownership at the time of distribution.
contract DiscretePayoutVault is ERC4626, Ownable {
    uint256 public constant PRECISION = 1e18;

    uint256 public totalProceeds;
    uint256 public proceedsPerShare;

    /// @dev Tracks user’s outstanding proceeds debt and last proceeds snapshot.
    struct UserData {
        uint256 proceedsDebt;
        uint256 lastProceedsPerShare;
    }

    mapping(address => UserData) public users;

    error AmountMustBeGreaterThanZero(uint256 amount);
    error NoSharesExistToDistribute();
    error NoProceedsToClaim();

    constructor(UsdToken asset) ERC4626(asset) ERC20("Share Token", "SHARE") Ownable(msg.sender) {}

    /// @notice Distributes proceeds to current share owners.
    function distributeProceeds(uint256 amount) external onlyOwner {
        if (amount == 0) revert AmountMustBeGreaterThanZero(amount);
        if (totalSupply() == 0) revert NoSharesExistToDistribute();

        UsdToken(asset()).mintTo(address(this), amount);

        proceedsPerShare += Math.mulDiv(amount, PRECISION, totalSupply());
        totalProceeds += amount;
    }

    /// @notice Claims the user's pending proceeds.
    function claimProceeds() public {
        _updateUserProceeds(msg.sender);

        uint256 owed = users[msg.sender].proceedsDebt;
        if (owed == 0) revert NoProceedsToClaim();

        users[msg.sender].proceedsDebt = 0;
        UsdToken(asset()).transfer(msg.sender, owed);
    }

    /// @notice Withdraws the user's assets after claiming pending proceeds.
    function withdraw() public returns (uint256) {
        claimProceeds();
        return ERC4626.redeem(balanceOf(msg.sender), msg.sender, msg.sender);
    }

    /// @dev Updates the user's proceeds debt and last snapshot based on current shares and proceeds.
    function _updateUserProceeds(address user) internal {
        uint256 shares = balanceOf(user);
        UserData storage data = users[user];

        if (shares > 0) {
            uint256 newDebt = Math.mulDiv(shares, proceedsPerShare - data.lastProceedsPerShare, PRECISION);
            data.proceedsDebt += newDebt;
        }

        data.lastProceedsPerShare = proceedsPerShare;
    }

    /// @dev Overrides deposit to handle proceeds tracking.
    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        _updateUserProceeds(receiver);
        return super.deposit(assets, receiver);
    }

    /// @dev Converts assets to shares on a 1:1 basis.
    function _convertToShares(uint256 assets, Math.Rounding) internal pure override returns (uint256) {
        return assets;
    }

    /// @dev Converts shares to assets on a 1:1 basis.
    function _convertToAssets(uint256 shares, Math.Rounding) internal pure override returns (uint256) {
        return shares;
    }
}
