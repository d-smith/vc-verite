// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./VerificationRegistry.sol";

contract KYCToken is ERC20, ERC20Burnable, Ownable {
    VerificationRegistry _verifiableRegistry;
    constructor(address initialOwner, VerificationRegistry verificationRegistry)
        ERC20("KYCToken", "KYCT")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 100000000 * 10 ** decimals());
        _verifiableRegistry = verificationRegistry;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function transfer(address to, uint256 amount)
        public virtual override returns (bool)
    {
        require(_verifiableRegistry.isVerified(to), "Destination account is not KYC'd");
        return super.transfer(to, amount);
    }
}
