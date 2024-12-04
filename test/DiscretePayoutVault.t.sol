// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "forge-std/Test.sol";
import {DiscretePayoutVault} from "../src/DiscretePayoutVault.sol";
import {UsdToken} from "../src/UsdToken.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

contract DiscretePayoutVaultTest is Test {
    UsdToken public usdToken;
    DiscretePayoutVault public vault;
    address public user1 = address(0x123);
    address public user2 = address(0x456);
    address public user3 = address(0x789);

    function setUp() public {
        usdToken = new UsdToken();
        vault = new DiscretePayoutVault(usdToken);
    }

    function testConvertToShares() public {
        uint256 amountToMint = 1000 * 1e18;
        uint256 shares = vault.convertToShares(amountToMint);
        assertEq(shares, amountToMint);
    }

    function testConvertToAssets() public {
        uint256 amountToMint = 1000 * 1e18;
        uint256 assets = vault.convertToAssets(amountToMint);
        assertEq(assets, amountToMint);
    }

    function testDeposit() public {
        uint256 amountToMint = 1000 * 1e18;

        vm.startPrank(user1);
        usdToken.mint(amountToMint);
        usdToken.approve(address(vault), amountToMint);
        vault.deposit(amountToMint, user1);
        vm.stopPrank();

        assertEq(usdToken.balanceOf(user1), 0); // Verify that usdTokens have been transfered
        assertEq(vault.balanceOf(user1), amountToMint); // Verify that shares have been minted 1:1 rate
        assertEq(usdToken.balanceOf(address(vault)), amountToMint); // Verify that vault holds the underlying
        assertEq(vault.totalSupply(), amountToMint); // Verify shares supply
    }

    function testDistributeProceeds() public {
        uint256 amountToMint = 1000 * 1e18;
        uint256 amountToDistribute = 500 * 1e18;

        vm.startPrank(user1);
        usdToken.mint(amountToMint);
        usdToken.approve(address(vault), amountToMint);
        vault.deposit(amountToMint, user1);
        vm.stopPrank();

        vault.distributeProceeds(amountToDistribute);

        assertEq(vault.totalProceeds(), amountToDistribute); // Verify total proceeds
        uint256 expectedProceedsPerShare = (amountToDistribute * 1e18) / vault.totalSupply(); // 0.5 proceed/share
        assertEq(vault.proceedsPerShare(), expectedProceedsPerShare); // Verify proceed per share
    }

    function testClaimProceeds() public {
        uint256 amountToMint = 1000 * 1e18;
        uint256 amountToDistribute = 500 * 1e18;

        vm.startPrank(user1);
        usdToken.mint(amountToMint);
        usdToken.approve(address(vault), amountToMint);
        vault.deposit(amountToMint, user1);
        vm.stopPrank();

        vault.distributeProceeds(amountToDistribute);

        // Claim proceeds for the user
        uint256 initialBalance = usdToken.balanceOf(user1);
        vm.prank(user1);
        vault.claimProceeds();

        // Assert that the user's balance has been updated with the proceeds
        uint256 expectedBalance = initialBalance + (amountToDistribute * vault.balanceOf(user1)) / vault.totalSupply();
        assertEq(usdToken.balanceOf(user1), expectedBalance);
    }

    function testClaimProceedsMultipleUsers() public {
        uint256 amountToMint1 = 1000 * 1e18;
        uint256 amountToMint2 = 700 * 1e18;
        uint256 amountToDistribute = 500 * 1e18;

        vm.startPrank(user1);
        usdToken.mint(amountToMint1);
        usdToken.approve(address(vault), amountToMint1);
        vault.deposit(amountToMint1, user1);
        vm.stopPrank();

        vm.startPrank(user2);
        usdToken.mint(amountToMint2);
        usdToken.approve(address(vault), amountToMint2);
        vault.deposit(amountToMint2, user2);
        vm.stopPrank();

        vault.distributeProceeds(amountToDistribute);

        // Initial balances for both users before claiming proceeds
        uint256 initialBalanceUser1 = usdToken.balanceOf(user1);
        uint256 initialBalanceUser2 = usdToken.balanceOf(user2);

        // User1 claims proceeds
        vm.prank(user1);
        vault.claimProceeds();

        // User2 claims proceeds
        vm.prank(user2);
        vault.claimProceeds();

        // Calculate expected proceeds for each user based on their share WITHOUT PRECISION ROUNDING
        uint256 user1Proceeds = (amountToDistribute * vault.balanceOf(user1)) / vault.totalSupply();
        uint256 user2Proceeds = (amountToDistribute * vault.balanceOf(user2)) / vault.totalSupply();

        // Verify that the balances are updated correctly for each user
        assertApproxEqRel(usdToken.balanceOf(user1), initialBalanceUser1 + user1Proceeds, 1e14); // 1e14 is equivalant to 0.01%
        assertApproxEqRel(usdToken.balanceOf(user2), initialBalanceUser2 + user2Proceeds, 1e14);

        // Verify that we don't accumulate bad debt
        assertGe(initialBalanceUser1 + user1Proceeds, usdToken.balanceOf(user1));
        assertGe(initialBalanceUser2 + user2Proceeds, usdToken.balanceOf(user2));
    }

    function testClaimProceedsMultipleDistributions() public {
        // Define deposit amounts for users
        uint256 amountToMint1 = 1000 * 1e18;
        uint256 amountToMint2 = 700 * 1e18;

        // Define multiple distributions
        uint256[3] memory proceeds = [uint256(500 * 1e18), uint256(300 * 1e18), uint256(200 * 1e18)];

        // User1 deposits
        vm.startPrank(user1);
        usdToken.mint(amountToMint1);
        usdToken.approve(address(vault), amountToMint1);
        vault.deposit(amountToMint1, user1);
        vm.stopPrank();

        // User2 deposits
        vm.startPrank(user2);
        usdToken.mint(amountToMint2);
        usdToken.approve(address(vault), amountToMint2);
        vault.deposit(amountToMint2, user2);
        vm.stopPrank();

        // Distribute proceeds in multiple rounds
        for (uint256 i = 0; i < proceeds.length; i++) {
            vault.distributeProceeds(proceeds[i]);
        }

        // Total distributed proceeds
        uint256 totalDistributed = proceeds[0] + proceeds[1] + proceeds[2];

        // Initial balances for both users
        uint256 initialBalanceUser1 = usdToken.balanceOf(user1);
        uint256 initialBalanceUser2 = usdToken.balanceOf(user2);

        // Users claim their proceeds
        vm.prank(user1);
        vault.claimProceeds();
        vm.prank(user2);
        vault.claimProceeds();

        // Calculate expected proceeds for each user
        uint256 user1Proceeds = Math.mulDiv(totalDistributed, vault.balanceOf(user1), vault.totalSupply());
        uint256 user2Proceeds = Math.mulDiv(totalDistributed, vault.balanceOf(user2), vault.totalSupply());

        // Verify the final balances for both users
        assertApproxEqRel(usdToken.balanceOf(user1), initialBalanceUser1 + user1Proceeds, 1e14); // 0.01% tolerance
        assertApproxEqRel(usdToken.balanceOf(user2), initialBalanceUser2 + user2Proceeds, 1e14);

        // Verify no bad debt accumulation
        assertGe(initialBalanceUser1 + user1Proceeds, usdToken.balanceOf(user1));
        assertGe(initialBalanceUser2 + user2Proceeds, usdToken.balanceOf(user2));
    }

    function testWithdraw() public {
        uint256 amountToMint = 1000 * 1e18;
        uint256 amountToDistribute = 500 * 1e18;

        vm.startPrank(user1);
        usdToken.mint(amountToMint);
        usdToken.approve(address(vault), amountToMint);
        vault.deposit(amountToMint, user1);
        vm.stopPrank();

        vault.distributeProceeds(amountToDistribute);

        uint256 user1Proceeds = (amountToDistribute * vault.balanceOf(user1)) / vault.totalSupply();

        vm.prank(user1);
        vault.withdraw();
        assertEq(user1Proceeds + amountToMint, usdToken.balanceOf(user1));
    }

    function testSeveralProceedsDistribution() public {
        uint256 user1Deposit = 1000 * 1e18;
        uint256 user2Deposit = 1000 * 1e18;
        uint256 lateUserDeposit = 10000 * 1e18;
        uint256 firstProceedsAmount = 10000 * 1e18;
        uint256 secondProceedsAmount = 5000 * 1e18;

        // Step 1: User1 deposits 1000 USD Tokens
        vm.startPrank(user1);
        usdToken.mint(user1Deposit);
        usdToken.approve(address(vault), user1Deposit);
        vault.deposit(user1Deposit, user1);
        vm.stopPrank();

        // Step 2: User2 deposits 1000 USD Tokens
        vm.startPrank(user2);
        usdToken.mint(user2Deposit);
        usdToken.approve(address(vault), user2Deposit);
        vault.deposit(user2Deposit, user2);
        vm.stopPrank();

        // Step 3: Owner distributes 10,000 proceeds
        vault.distributeProceeds(firstProceedsAmount);

        // Step 4: User3 deposits 10,000 USD Tokens (late entry)
        vm.startPrank(user3);
        usdToken.mint(lateUserDeposit);
        usdToken.approve(address(vault), lateUserDeposit);
        vault.deposit(lateUserDeposit, user3);
        vm.stopPrank();

        // Step 5: User3 claims proceeds (should revert with "NoProceedsToClaim")
        vm.startPrank(user3);
        vm.expectRevert(DiscretePayoutVault.NoProceedsToClaim.selector);
        vault.claimProceeds();
        vm.stopPrank();

        // Step 6: User1 claims proceeds (should receive 5,000 USD Tokens)
        uint256 initialBalanceUser1 = usdToken.balanceOf(user1);
        vm.prank(user1);
        vault.claimProceeds();
        uint256 finalBalanceUser1 = usdToken.balanceOf(user1);

        uint256 expectedUser1Proceeds = firstProceedsAmount / 2; // 50% share of first proceeds
        assertEq(
            finalBalanceUser1,
            initialBalanceUser1 + expectedUser1Proceeds,
            "User1 should receive 5,000 USD Tokens as proceeds"
        );

        // Step 7: Owner distributes an additional 5,000 proceeds
        vault.distributeProceeds(secondProceedsAmount);

        // Step 8: User3 claims their share of the second proceeds
        uint256 initialBalanceUser3 = usdToken.balanceOf(user3);
        vm.prank(user3);
        vault.claimProceeds();

        uint256 totalSupply = vault.totalSupply();
        uint256 user3Proceeds = (secondProceedsAmount * vault.balanceOf(user3)) / totalSupply;

        // User 3 should have received 4166.66 tokens
        assertApproxEqRel(usdToken.balanceOf(user3), initialBalanceUser3 + user3Proceeds, 1e14);
    }
}
