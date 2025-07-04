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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface MErc20Interface {
  /**
   * User Interface **
   */
  function mint(
    uint256 mintAmount
  ) external returns (uint256);
  function redeem(
    uint256 redeemTokens
  ) external returns (uint256);
  function redeemUnderlying(
    uint256 redeemAmount
  ) external returns (uint256);
  function borrow(
    uint256 borrowAmount
  ) external returns (uint256);
  function repayBorrow(
    uint256 repayAmount
  ) external returns (uint256);
  function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);
  function exchangeRateCurrent() external returns (uint256);
  // function liquidateBorrow(address borrower, uint256 repayAmount, MTokenInterface mTokenCollateral)
  //     external
  //     returns (uint256);
  // function sweepToken(EIP20NonStandardInterface token) external;
}

interface ComptrollerInterface {
  /// @notice Indicator that this is a Comptroller contract (for inspection)
  // bool public constant isComptroller = true;

  /**
   * Assets You Are In **
   */
  function enterMarkets(
    address[] calldata mTokens
  ) external returns (uint256[] memory);
  function exitMarket(
    address mToken
  ) external returns (uint256);
}

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
  /// @notice Deposit ether to get wrapped ether
  function deposit() external payable;

  /// @notice Withdraw wrapped ether to get ether
  function withdraw(
    uint256
  ) external;
}
