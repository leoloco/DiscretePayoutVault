// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @title UsdToken
 * @dev Implementation of an ERC-20 token named "USD Token" with the symbol "USDT".
 *      This contract allows minting of new tokens to the caller or a specified address.
 */
contract UsdToken is ERC20 {
    /**
     * @dev Sets the token name to "USD Token" and symbol to "USDT".
     * The constructor calls the ERC20 constructor with the name and symbol.
     */
    constructor() ERC20("USD Token", "USDT") {}

    /**
     * @notice Mints new tokens to the caller (msg.sender).
     * @dev Calls the internal _mint function of ERC20 to mint tokens to the sender's address.
     * @param value The amount of tokens to mint.
     */
    function mint(uint256 value) public {
        _mint(msg.sender, value);
    }

    /**
     * @notice Mints new tokens to a specified address.
     * @dev Calls the internal _mint function of ERC20 to mint tokens to a specified address.
     * @param to The address to receive the minted tokens.
     * @param value The amount of tokens to mint.
     */
    function mintTo(address to, uint256 value) public {
        _mint(to, value);
    }
}
