// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import './InterestRateModel.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

/**
 * @title Compound's WhitePaperInterestRateModel Contract
 * @author Compound
 * @notice The parameterized model described in section 2.4 of the original Compound Protocol whitepaper
 */
contract WhitePaperInterestRateModel is InterestRateModel {
  using SafeMath for uint256;

  event NewInterestParams(uint256 baseRatePerSecond, uint256 multiplierPerSecond);

  /**
   * @notice The multiplier of utilization rate that gives the slope of the interest rate
   */
  uint256 public multiplierPerSecond;

  /**
   * @notice The base interest rate which is the y-intercept when utilization rate is 0
   */
  uint256 public baseRatePerSecond;

  /**
   * @notice Construct an interest rate model
   * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
   * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
   */
  constructor(uint256 baseRatePerYear, uint256 multiplierPerYear) {
    baseRatePerSecond = baseRatePerYear.div(secondsPerYear);
    multiplierPerSecond = multiplierPerYear.div(secondsPerYear);
    emit NewInterestParams(baseRatePerSecond, multiplierPerSecond);
  }

  /**
   * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market (currently unused)
   * @return The utilization rate as a mantissa between [0, 1e18]
   */
  function utilizationRate(uint256 cash, uint256 borrows, uint256 reserves) public pure returns (uint256) {
    // Utilization rate is 0 when there are no borrows
    if (borrows == 0) {
      return 0;
    }
    if (reserves > cash && (borrows + cash - reserves > 0)) {
      return 1e18;
    }

    return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
  }

  /**
   * @notice Calculates the current borrow rate per block, with the error code expected by the market
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getBorrowRate(uint256 cash, uint256 borrows, uint256 reserves) public view override returns (uint256) {
    uint256 ur = utilizationRate(cash, borrows, reserves);
    return ur.mul(multiplierPerSecond).div(1e18).add(baseRatePerSecond);
  }

  /**
   * @notice Calculates the current supply rate per block
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @param reserveFactorMantissa The current reserve factor for the market
   * @return The supply rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) public view override returns (uint256) {
    uint256 oneMinusReserveFactor = uint256(1e18).sub(reserveFactorMantissa);
    uint256 borrowRate = getBorrowRate(cash, borrows, reserves);
    uint256 rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
    return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
  }
}
