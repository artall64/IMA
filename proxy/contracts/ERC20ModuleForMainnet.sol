/**
 *   ERC20ModuleForMainnet.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2019-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE-IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE-IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE-IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.0;

import "./Permissions.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";

interface ILockAndDataERC20M {
    function ERC20Tokens(uint index) external returns (address);
    function ERC20Mapper(address contractERC20) external returns (uint);
    function ERC20ApprovedTokens(address contractERC20) external returns (bool);
    function addERC20Token(address contractERC20) external returns (uint);
    function sendERC20(address contractHere, address to, uint amount) external returns (bool);
}


contract ERC20ModuleForMainnet is Permissions {

    event EncodedData(bytes data);
    event EncodedRawData(bytes data);
    event SentERC20(bool result);

    constructor(address newLockAndDataAddress) Permissions(newLockAndDataAddress) public {
        // solium-disable-previous-line no-empty-blocks
    }

    function receiveERC20(address contractHere, address to, uint amount, bool isRAW) public allow("DepositBox") returns (bytes memory data) {
        address lockAndDataERC20 = ContractManager(lockAndDataAddress).permitted(keccak256(abi.encodePacked("LockAndDataERC20")));
        require(ILockAndDataERC20M(lockAndDataERC20).ERC20ApprovedTokens(contractHere), "This ERC20 token is not in the list of trusted");
        if (!isRAW) {
            uint contractPosition = ILockAndDataERC20M(lockAndDataERC20).ERC20Mapper(contractHere);
            if (contractPosition == 0) {
                contractPosition = ILockAndDataERC20M(lockAndDataERC20).addERC20Token(contractHere);
            }
            data = encodeData(contractHere, contractPosition, to, amount);
            emit EncodedData(bytes(data));
            return data;
        } else {
            data = encodeRawData(to, amount);
            emit EncodedRawData(bytes(data));
            return data;
        }
    }

    function sendERC20(address to, bytes memory data) public allow("DepositBox") returns (bool) {
        address lockAndDataERC20 = ContractManager(lockAndDataAddress).permitted(keccak256(abi.encodePacked("LockAndDataERC20")));
        uint contractPosition;
        address contractAddress;
        address receiver;
        uint amount;
        if (to == address(0)) {
            (contractPosition, receiver, amount) = fallbackDataParser(data);
            contractAddress = ILockAndDataERC20M(lockAndDataERC20).ERC20Tokens(contractPosition);
        } else {
            (receiver, amount) = fallbackRawDataParser(data);
            contractAddress = to;
        }
        bool variable = ILockAndDataERC20M(lockAndDataERC20).sendERC20(contractAddress, receiver, amount);
        emit SentERC20(bool(variable));
        return variable;
    }

    function getReceiver(address to, bytes memory data) public pure returns (address receiver) {
        uint contractPosition;
        uint amount;
        if (to == address(0)) {
            (contractPosition, receiver, amount) = fallbackDataParser(data);
        } else {
            (receiver, amount) = fallbackRawDataParser(data);
        }
    }

    function encodeData(address contractHere, uint contractPosition, address to, uint amount) internal view returns (bytes memory data) {
        string memory name = ERC20Detailed(contractHere).name();
        uint8 decimals = ERC20Detailed(contractHere).decimals();
        string memory symbol = ERC20Detailed(contractHere).symbol();
        uint totalSupply = ERC20Detailed(contractHere).totalSupply();
        data = abi.encodePacked(
            bytes1(uint8(3)),
            bytes32(contractPosition),
            bytes32(bytes20(to)),
            bytes32(amount),
            bytes(name).length,
            name,
            bytes(symbol).length,
            symbol,
            decimals,
            totalSupply
        );
    }

    function encodeRawData(address to, uint amount) internal pure returns (bytes memory data) {
        data = abi.encodePacked(
            bytes1(uint8(19)),
            bytes32(bytes20(to)),
            bytes32(amount)
        );
    }

    function fallbackDataParser(bytes memory data)
        internal
        pure
        returns (uint, address payable, uint)
    {
        bytes32 contractIndex;
        bytes32 to;
        bytes32 token;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            contractIndex := mload(add(data, 33))
            to := mload(add(data, 65))
            token := mload(add(data, 97))
        }
        return (
            uint(contractIndex), address(bytes20(to)), uint(token)
        );
    }

    function fallbackRawDataParser(bytes memory data)
        internal
        pure
        returns (address payable, uint)
    {
        bytes32 to;
        bytes32 token;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            to := mload(add(data, 33))
            token := mload(add(data, 65))
        }
        return (address(bytes20(to)), uint(token));
    }

}