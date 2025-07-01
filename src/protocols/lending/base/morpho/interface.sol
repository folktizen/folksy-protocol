// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

//////////////////////////////////////////////////////////////////
// @title   Folksy Protocol
// @notice  More at: https://folksy.space
// @version 1.1.0.CENDOL
// @author  Folktizen Labs
//////////////////////////////////////////////////////////////////
//
//    _______   ______    ___       __   ___   ________  ___  ___
//   /"     "| /    " \  |"  |     |/"| /  ") /"       )|"  \/"  |
//  (: ______)// ____  \ ||  |     (: |/   / (:   \___/  \   \  /
//   \/    | /  /    ) :)|:  |     |    __/   \___  \     \\  \/
//   // ___)(: (____/ //  \  |___  (// _  \    __/  \\    /   /
//  (:  (    \        /  ( \_|:  \ |: | \  \  /" \   :)  /   /
//   \__/     \"_____/    \_______)(__|  \__)(_______/  |___/
//
//////////////////////////////////////////////////////////////////

interface MorphInterface {
    /**
     * User Interface **
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}
