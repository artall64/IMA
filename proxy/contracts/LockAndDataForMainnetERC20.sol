/**
 *   LockAndDataForMainnetERC20.sol - SKALE Interchain Messaging Agent
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
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";


contract LockAndDataForMainnetERC20 is Permissions {

    event SendedERC20(bool result);
    event AddedERC20Token(uint index);
    event ERC20ApprovedAddressAdded(address approvedTokenAddress);


    mapping(uint => address) public ERC20Tokens;
    mapping(address => uint) public ERC20Mapper;
    mapping(address => bool) public ERC20ApprovedTokens;
    uint newIndexERC20 = 1;

    constructor(address lockAndDataAddress) Permissions(lockAndDataAddress) public {
        // solium-disable-previous-line no-empty-blocks
    }

    function sendERC20(address contractHere, address to, uint amount) public allow("ERC20Module") returns (bool) {
        require(IERC20(contractHere).balanceOf(address(this)) >= amount, "Not enough money");
        require(IERC20(contractHere).transfer(to, amount), "something went wrong with `transfer` in ERC20");
        emit SendedERC20(bool(true));
        return true;
    }

    function addERC20Token(address addressERC20) public allow("ERC20Module") returns (uint) {
        uint index = newIndexERC20;
        ERC20Tokens[index] = addressERC20;
        ERC20Mapper[addressERC20] = index;
        newIndexERC20++;
        emit AddedERC20Token(uint(index));
        return index;
    }

    function addERC20ApprovedToken(address approvedTokenAddress) public onlyOwner {
        ERC20ApprovedTokens[approvedTokenAddress] = true;
        emit ERC20ApprovedAddressAdded(approvedTokenAddress);
    }

}