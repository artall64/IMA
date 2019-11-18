/**
 *   Permissions.sol - SKALE Interchain Messaging Agent
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

pragma solidity ^0.5.3;

import "./Ownable.sol";

interface IContractManager {
    function permitted(bytes32 contractName) external view returns (address);
}


/**
 * @title Permissions - connected module for Upgradeable approach, knows ContractManager
 * @author Artem Payvin
 */
contract Permissions is Ownable {

    // address of ContractManager
    address lockAndDataAddress;

    /**
     * @dev allow - throws if called by any account and contract other than the owner
     * or `contractName` contract
     * @param contractName - human readable name of contract
     */
    modifier allow(string memory contractName) {
        require(
            IContractManager(lockAndDataAddress).permitted(keccak256(abi.encodePacked(contractName))) == msg.sender ||
            owner == msg.sender, "Message sender is invalid"
        );
        _;
    }

    /**
     * @dev constructor - sets current address of ContractManager
     * @param newContractsAddress - current address of ContractManager
     */
    constructor(address newContractsAddress) public {
        lockAndDataAddress = newContractsAddress;
    }
}
