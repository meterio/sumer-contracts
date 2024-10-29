// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import './PriceOracle.sol';

interface IStUSD {
  function previewRedeem(uint256 shares) external view returns (uint256);
}

contract stUSDAdapter is PriceAdapter {
  uint256 constant EXP_SCALE = 1e18;

  constructor(address _correlatedToken /* stUSD */, address _underlyingToken /* sgUSD (USDA) */) {
    correlatedToken = _correlatedToken;
    underlyingToken = _underlyingToken;
  }

  /**
   * @notice Gets the stETH for 1 wstETH
   * @return amount Amount of stETH
   */
  function exchangeRate() public view override returns (uint256) {
    return IStUSD(correlatedToken).previewRedeem(EXP_SCALE);
  }
}
