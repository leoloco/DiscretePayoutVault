// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test} from "forge-std/Test.sol";
import {UsdToken} from "../src/UsdToken.sol";

contract UsdTokenTest is Test {
    UsdToken usdToken;
    address account1 = vm.addr(123);
    address account2 = vm.addr(456);

    function setUp() public {
        usdToken = new UsdToken();
    }

    function testMint() public {
        uint256 initialBalance = usdToken.balanceOf(account1);
        uint256 mintAmount = 1000;

        vm.prank(account1);
        usdToken.mint(mintAmount);

        uint256 newBalance = usdToken.balanceOf(account1);
        assertEq(newBalance, initialBalance + mintAmount, "Minting failed to increase balance");
    }
}
