// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {FHE, euint8, inEuint8,euint32,ebool} from "@fhenixprotocol/contracts/FHE.sol";

contract WrappingERC20 is ERC20 {

mapping(address => euint32) internal _encBalances;

constructor(string memory name, string memory symbol) ERC20(name,symbol) {
    _mint(msg.sender, 100 * 10** uint(decimals()));
}

function wrap(uint32 amount) public {
    require(balanceOf(msg.sender) >= amount, "Insufficient balance");
    _burn(msg.sender, amount);

    euint32 encryptedAmount = FHE.asEuint32(amount); // Convertir amount a euint32
    _encBalances[msg.sender] = FHE.add(_encBalances[msg.sender], encryptedAmount);
}

function unwrap(uint32 amount) public {
    euint32 encryptedAmount = FHE.asEuint32(amount); // Convertir amount a euint32
    FHE.req(FHE.gt(_encBalances[msg.sender], encryptedAmount));
    _encBalances[msg.sender] = FHE.sub(_encBalances[msg.sender], encryptedAmount);
    _mint(msg.sender, amount);
}

function transferEncrypted(address to, bytes calldata encryptedAmount) public {
    _transferEncrypted(to, FHE.asEuint32(encryptedAmount));
}

// Transfers an amount from the message sender address to the `to` address.
function _transferEncrypted(address to, euint32 amount) internal {
    _transferImpl(msg.sender, to, amount);
}

// Transfers an encrypted amount.
function _transferImpl(address from, address to, euint32 amount) internal {
    // Make sure the sender has enough tokens.
    FHE.req(FHE.lte(amount, _encBalances[from]));

    // Add to the balance of `to` and subtract from the balance of `from`.
    _encBalances[to] = FHE.add(_encBalances[to], amount);
    _encBalances[from] = FHE.sub(_encBalances[from], amount);
}

function hasBalance(address account) public view returns (ebool) {
    bool hasBalance = FHE.isInitialized(_encBalances[account]);
    return ebool.wrap(hasBalance ? 1 : 0);
}
}