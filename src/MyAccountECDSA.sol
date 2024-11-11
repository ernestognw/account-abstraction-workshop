// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PackedUserOperation} from "@openzeppelin/contracts/interfaces/draft-IERC4337.sol";
import {ERC4337Utils} from "@openzeppelin/contracts/account/utils/draft-ERC4337Utils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {AccountBase} from "./unreleased/draft-AccountBase.sol";
import {ERC7739Signer, EIP712} from "@openzeppelin/community-contracts/utils/cryptography/draft-ERC7739Signer.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract MyAccountECDSA is ERC7739Signer, AccountBase {
    constructor() EIP712("MyAccountECDSA", "1") {}

    function signer() public view virtual returns (address) {
        return abi.decode(Clones.fetchCloneArgs(address(this)), (address));
    }

    function _validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256) {
        return
            _isValidSignature(userOpHash, userOp.signature)
                ? ERC4337Utils.SIG_VALIDATION_SUCCESS
                : ERC4337Utils.SIG_VALIDATION_FAILED;
    }

    function _validateSignature(
        bytes32 hash,
        bytes calldata signature
    ) internal view virtual override returns (bool) {
        (address recovered, ECDSA.RecoverError err, ) = ECDSA.tryRecover(
            hash,
            signature
        );
        return signer() == recovered && err == ECDSA.RecoverError.NoError;
    }
}
