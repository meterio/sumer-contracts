// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract PriceOracle {
  /// @notice Indicator that this is a PriceOracle contract (for inspection)
  bool public constant isPriceOracle = true;

  /**
   * @notice Get the underlying price of a cToken asset
   * @param cToken The cToken to get the underlying price of
   * @return The underlying asset price mantissa (scaled by 1e18).
   *  Zero means the price is unavailable.
   */
  function getUnderlyingPrice(address cToken) external view virtual returns (uint256);

  function getPrice(address asset) external view virtual returns (uint256);
}

abstract contract PriceAdapter {
  address underlyingToken;
  address correlatedToken;

  /**
   * @notice returns underlying tokens for 1 correlatedToken
   */
  function exchangeRate() external view virtual returns (uint256);
}
