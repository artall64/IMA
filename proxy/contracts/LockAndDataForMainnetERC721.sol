pragma solidity ^0.6.0;

import "./PermissionsForMainnet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Full.sol";


contract LockAndDataForMainnetERC721 is PermissionsForMainnet {

    mapping(uint => address) public erc721Tokens;
    mapping(address => uint) public erc721Mapper;
    // mapping(uint => uint) public mintToken;
    uint newIndexERC721 = 1;

    constructor(address _lockAndDataAddress) PermissionsForMainnet(_lockAndDataAddress) public {
        // solium-disable-previous-line no-empty-blocks
    }

    function sendERC721(address contractHere, address to, uint tokenId) external allow("ERC721Module") returns (bool) {
        if (IERC721Full(contractHere).ownerOf(tokenId) == address(this)) {
            IERC721Full(contractHere).transferFrom(address(this), to, tokenId);
            require(IERC721Full(contractHere).ownerOf(tokenId) == to, "Did not transfer");
        } // else {
        //     //mint!!!
        // }
        return true;
    }

    function addERC721Token(address addressERC721) external allow("ERC721Module") returns (uint) {
        uint index = newIndexERC721;
        erc721Tokens[index] = addressERC721;
        erc721Mapper[addressERC721] = index;
        newIndexERC721++;
        return index;
    }
}