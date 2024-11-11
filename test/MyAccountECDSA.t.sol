// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PackedUserOperation} from "@openzeppelin/contracts/interfaces/draft-IERC4337.sol";
import {ERC4337Utils} from "@openzeppelin/contracts/account/utils/draft-ERC4337Utils.sol";
import {MyAccountECDSA} from "../src/MyAccountECDSA.sol";
import {MyAccountECDSAFactory} from "../src/MyAccountECDSAFactory.sol";
import {ERC7739Utils} from "@openzeppelin/community-contracts/utils/cryptography/draft-ERC7739Utils.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MyAccountECDSATest is Test {
    MyAccountECDSAFactory public myFactory = new MyAccountECDSAFactory();
    MyAccountECDSA public myAccount;
    address alice;
    uint256 privateKey;

    bytes32 private constant TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    function setUp() public {
        (alice, privateKey) = makeAddrAndKey("alice");
        myAccount = MyAccountECDSA(payable(myFactory.clone(alice, bytes32(0))));
    }

    function test_validateUserOp(
        uint256 nonce,
        bytes memory initCode,
        bytes memory callData,
        bytes32 accountGasLimits,
        uint256 preVerificationGas,
        bytes32 gasFees,
        bytes memory paymasterAndData
    ) public {
        PackedUserOperation memory userOp = _mockUserOp(address(myAccount));
        userOp.nonce = nonce;
        userOp.initCode = initCode;
        userOp.callData = callData;
        userOp.accountGasLimits = accountGasLimits;
        userOp.preVerificationGas = preVerificationGas;
        userOp.gasFees = gasFees;
        userOp.paymasterAndData = paymasterAndData;

        bytes32 userOpHash = _hashUserOp(userOp);
        (uint8 v, bytes32 r, bytes32 s) = _signPersonal(userOpHash);
        userOp.signature = abi.encodePacked(r, s, v);

        vm.prank(address(myAccount.entryPoint()));
        uint256 result = myAccount.validateUserOp(userOp, userOpHash, 0);
        assertEq(result, ERC4337Utils.SIG_VALIDATION_SUCCESS);
    }

    function _mockUserOp(
        address sender
    ) internal pure returns (PackedUserOperation memory userOp) {
        return
            PackedUserOperation({
                sender: sender,
                nonce: 0,
                initCode: hex"00",
                callData: hex"00",
                accountGasLimits: bytes32(0),
                preVerificationGas: 0,
                gasFees: bytes32(0),
                paymasterAndData: hex"00",
                signature: hex"00"
            });
    }

    function _hashUserOp(
        PackedUserOperation memory userOp
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    userOp.sender,
                    userOp.nonce,
                    keccak256(userOp.initCode),
                    keccak256(userOp.callData),
                    userOp.accountGasLimits,
                    userOp.preVerificationGas,
                    userOp.gasFees,
                    keccak256(userOp.paymasterAndData)
                )
            );
    }

    function _signPersonal(
        bytes32 hash
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 personalSignStructHash = ERC7739Utils.personalSignStructHash(
            hash
        );
        (
            ,
            string memory name,
            string memory version,
            ,
            address verifyingContract,
            ,

        ) = myAccount.eip712Domain();
        return
            vm.sign(
                privateKey,
                MessageHashUtils.toTypedDataHash(
                    keccak256(
                        abi.encode(
                            keccak256(
                                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                            ),
                            keccak256(abi.encodePacked(name)),
                            keccak256(abi.encodePacked(version)),
                            block.chainid,
                            verifyingContract
                        )
                    ),
                    personalSignStructHash
                )
            );
    }
}
