// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {MyAccountECDSA} from "./MyAccountECDSA.sol";

contract MyAccountECDSAFactory {
    using Clones for address;

    address private immutable _impl = address(new MyAccountECDSA());

    function predictAddress(
        address signer,
        bytes32 salt
    ) public view returns (address) {
        return
            _impl.predictDeterministicAddressWithImmutableArgs(
                abi.encode(signer),
                salt,
                address(this)
            );
    }

    function clone(address signer, bytes32 salt) public returns (address) {
        address predicted = predictAddress(signer, salt);
        if (predicted.code.length == 0) {
            address obtained = _impl.cloneDeterministicWithImmutableArgs(
                abi.encode(signer),
                salt
            );
            assert(obtained == predicted);
        }
        return predicted;
    }
}
