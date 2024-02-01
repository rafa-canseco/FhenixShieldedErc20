// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {FHE, euint8, inEuint8,euint32,ebool} from "@fhenixprotocol/contracts/FHE.sol";

contract WrappingERC20 is ERC20 {

    // Mapeo de balances encriptados por dirección
    mapping(address => euint32) internal _encBalances;

    // Constructor que inicializa el contrato con un nombre y símbolo, y acuña tokens para el remitente
    constructor(string memory name, string memory symbol) ERC20(name,symbol) {
        _mint(msg.sender, 100 * 10** uint(decimals()));
    }

    // Función para envolver tokens y convertirlos en su forma encriptada
    function wrap(uint32 amount) public {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);

        euint32 encryptedAmount = FHE.asEuint32(amount); // Convertir amount a euint32
        _encBalances[msg.sender] = FHE.add(_encBalances[msg.sender], encryptedAmount);
    }

    // Función para desenvolver tokens y convertirlos de su forma encriptada a la forma normal
    function unwrap(uint32 amount) public {
        euint32 encryptedAmount = FHE.asEuint32(amount); // Convertir amount a euint32
        FHE.req(FHE.gt(_encBalances[msg.sender], encryptedAmount));
        _encBalances[msg.sender] = FHE.sub(_encBalances[msg.sender], encryptedAmount);
        _mint(msg.sender, amount);
    }

    // Función pública para transferir una cantidad encriptada a otra dirección
    function transferEncrypted(address to, bytes calldata encryptedAmount) public {
        _transferEncrypted(to, FHE.asEuint32(encryptedAmount));
    }

    // Función interna para transferir una cantidad encriptada desde la dirección del remitente a la dirección 'to'
    function _transferEncrypted(address to, euint32 amount) internal {
        _transferImpl(msg.sender, to, amount);
    }

    // Función interna para implementar la transferencia de una cantidad encriptada
    function _transferImpl(address from, address to, euint32 amount) internal {
        // Asegurarse de que el remitente tenga suficientes tokens
        FHE.req(FHE.lte(amount, _encBalances[from]));

        // Añadir al balance de 'to' y restar del balance de 'from'
        _encBalances[to] = FHE.add(_encBalances[to], amount);
        _encBalances[from] = FHE.sub(_encBalances[from], amount);
    }

    // Función para verificar si una cuenta tiene balance encriptado
    function hasBalance(address account) public view returns (ebool) {
        bool hasBalance = FHE.isInitialized(_encBalances[account]);
        return ebool.wrap(hasBalance ? 1 : 0);
    }
}
