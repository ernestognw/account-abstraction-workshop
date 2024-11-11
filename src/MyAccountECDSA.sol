// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PackedUserOperation} from "@openzeppelin/contracts/interfaces/draft-IERC4337.sol";
import {ERC4337Utils} from "@openzeppelin/contracts/account/utils/draft-ERC4337Utils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {AccountBase} from "./unreleased/draft-AccountBase.sol";

contract MyAccountECDSA is AccountBase {
    address private immutable _signer;

    constructor(address signerAddr) {
        _signer = signerAddr;
    }

    function signer() public view virtual returns (address) {
        return _signer;
    }

    function _validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256) {
        (address recovered, ECDSA.RecoverError err, ) = ECDSA.tryRecover(
            userOpHash,
            userOp.signature
        );
        return
            signer() == recovered && err == ECDSA.RecoverError.NoError
                ? ERC4337Utils.SIG_VALIDATION_SUCCESS
                : ERC4337Utils.SIG_VALIDATION_FAILED;
    }
}
