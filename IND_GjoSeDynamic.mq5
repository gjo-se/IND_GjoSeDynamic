/*

   IND_GjoSeDynamic.mq5
   Copyright 2021, Gregory Jo
   https://www.gjo-se.com

   Version History
   ===============

   1.0.0 Initial version

   ===============

//*/

#include <GjoSe\\Objects\\InclVLine.mqh>
#include <Mql5Book\Price.mqh>
#include <MovingAverages.mqh>

#property   copyright   "2021, GjoSe"
#property   link        "http://www.gjo-se.com"
#property   description "GjoSe Dynamic"
#define     VERSION "1.0.0"
#property   version VERSION
#property   strict

#property indicator_separate_window

#property indicator_buffers   8
#property indicator_plots     3

#property indicator_type1     DRAW_COLOR_HISTOGRAM
#property indicator_color1    clrGainsboro, clrGreen, clrForestGreen, clrRed, clrCrimson, clrBlack
#property indicator_width1    2
#property indicator_label1    "fastSlow"

#property indicator_type2     DRAW_COLOR_LINE
#property indicator_color2    clrGray, clrSpringGreen, clrGreen, clrLightPink, clrRed
#property indicator_width2    3
#property indicator_style2    STYLE_DOT
#property indicator_label2    "fastSlowSignal"

#property indicator_type3     DRAW_LINE
#property indicator_color3    clrGold
#property indicator_width3    2
#property indicator_label3    "middleSlow"

//#property indicator_type3     DRAW_LINE
//#property indicator_color3    clrBlack
//#property indicator_width3    1
//#property indicator_label3    "middleSelf"
//
//
//#property indicator_type5     DRAW_LINE
//#property indicator_color5    clrRed
//#property indicator_width5    1
//#property indicator_label5    "slowSelf"
//

bool                      ShowErrorMessages = true;

input ENUM_TIMEFRAMES     InpTimeframe = PERIOD_M5;
input int                 InpFastMAPeriod = 6;
input int                 InpMiddleMAPeriod = 100;
input int                 InpSlowMAPeriod = 200;
//input int                  InpMinDynamic = 100;
//input int                  InpMaxDynamic = 600;
//input int                  InpFastSlowDynamic = 20;
//input int                  InpINDFastSlowSignalOffset = 15;
//input int                  InpCandleCountFastSlowDynamic = 10;


const int   ROTATION_AREA = 0; // clrGainsboro
const int   UP_TREND = 1; // clrSpringGreen, clrGreenYellow
const int   UP_TREND_STRONG = 2; // clrGreen
const int   DOWN_TREND = 3; // clrLightPink,
const int   DOWN_TREND_STRONG = 4; // clrRed
const int   SIGNAL_OUT = 5; // clrBlack

double      ExtFastMaBuffer[];
double      ExtFastMaTmpArray[];
int         ExtFastMaHandle;

double      ExtMiddleMaBuffer[];
double      ExtMiddleMaTmpArray[];
int         ExtMiddleMaHandle;

double      ExtSlowMaBuffer[];
double      ExtSlowMaTmpArray[];
int         ExtSlowMaHandle;


double      FastSlowBuffer[];
double      FastSlowColorBuffer[];
double      FastSlowSignalBuffer[];
double      FastSlowSignalColorBuffer[];

double      MiddleSlowBuffer[];

//double      MiddleSelfBuffer[];
//double      SlowSelfBuffer[];



int         periodRatio = 1;
int         periodSecondsTimeFrame1 = 0;
int         periodSecondsTimeFrame2 = 0;
double      sellSessionMaxDynamic = 0;
double      buySessionMaxDynamic = 0;
bool        sellIsTradeable = false;
double      fastSlowSignalHighestHighValue = -10000;
double      fastSlowSignalLowestLowValue = 10000;
int         fastSlowSignalHighestHighIndex = 0;
int         fastSlowSignalLowestLowIndex = 0;

//double      fastCrossedSlowFromBelowValue = 0;
//int         fastCrossedSlowFromBelowIndex = 0;
//datetime    fastCrossedSlowFromBelowTime = 0;
//int         fastCrossedSlowFromAboveIndex = 0;
//datetime    fastCrossedSlowFromAboveTime = 0;
//double      middleCrossedSlowFromBelowValue = 0;
//int         middleCrossedSlowFromBelowIndex = 0;
//double      middleCrossedSlowFromAboveValue = 0;
//int         middleCrossedSlowFromAboveIndex = 0;
//double      middleLowestLow = 100 / Point();
//double      middleLowestLowTmp = 0;
//int         middleLowestLowIndex = 0;
//datetime    middleLowestLowTime = 0;
//
//double      middleHighestHigh = 0;
//double      middlehighestHighTmp = 0;
//int         middleHighestHighIndex = 0;
//datetime    middleHighestHighTime = 0;
datetime    fastSlowSignalHighestHighTime = 0;
datetime    fastSlowSignalLowestLowTime = 0;
//
//const string MIDDLE_CROSSED_SLOW_FROM_BELOW = "middleCrossedSlowFromBelow";
//const string MIDDLE_CROSSED_SLOW_FROM_ABOVE = "middleCrossedSlowFromAbove";
const string FAST_SLOW_SIGNAL_HIGHEST_HIGH = "fastSlowSignalHighestHigh";
const string FAST_SLOW_SIGNAL_LOWEST_LOW = "fastSlowSignalLowestLow";

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit() {

   SetIndexBuffer(0, FastSlowBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, FastSlowColorBuffer, INDICATOR_COLOR_INDEX);

   SetIndexBuffer(2, FastSlowSignalBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, FastSlowSignalColorBuffer, INDICATOR_COLOR_INDEX);

   SetIndexBuffer(4, MiddleSlowBuffer, INDICATOR_DATA);

//   SetIndexBuffer(2, MiddleSelfBuffer, INDICATOR_DATA);
//   SetIndexBuffer(4, SlowSelfBuffer, INDICATOR_DATA);


   SetIndexBuffer(5, ExtFastMaBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(6, ExtMiddleMaBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(7, ExtSlowMaBuffer, INDICATOR_CALCULATIONS);

   periodSecondsTimeFrame1 = PeriodSeconds();
   periodSecondsTimeFrame2 = PeriodSeconds(InpTimeframe);

   if(periodSecondsTimeFrame1 < periodSecondsTimeFrame2) {
      periodRatio = periodSecondsTimeFrame2 / periodSecondsTimeFrame1;
   }

   IndicatorSetString(INDICATOR_SHORTNAME, "Dynamic(" + string(InpFastMAPeriod) + "," + string(InpMiddleMAPeriod) + "," + string(InpSlowMAPeriod) + ")");

   createVLine(FAST_SLOW_SIGNAL_HIGHEST_HIGH, 0, clrGreen, 1, STYLE_DOT);
   createVLine(FAST_SLOW_SIGNAL_LOWEST_LOW, 0, clrRed, 1, STYLE_DOT);
//   createVLine(MIDDLE_CROSSED_SLOW_FROM_BELOW, 0, clrRed);
//   createVLine(MIDDLE_CROSSED_SLOW_FROM_ABOVE, 0, clrGreen);

   ExtFastMaHandle = iMA(Symbol(), InpTimeframe, InpFastMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
   ExtMiddleMaHandle = iMA(Symbol(), InpTimeframe, InpMiddleMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
   ExtSlowMaHandle = iMA(Symbol(), InpTimeframe, InpSlowMAPeriod, 0, MODE_SMA, PRICE_CLOSE);

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int pRatesTotal,
                const int pPrevCalculated,
                const datetime &pTime[],
                const double &pOpen[],
                const double &pHigh[],
                const double &pLow[],
                const double &pClose[],
                const long &pTickVolume[],
                const long &pVolume[],
                const int &pSpread[]         ) {

   int      barsTimeFrameCount;
   int      start, i;
   int      currentCandle;
   int      calculatedBars;
   double   fastSlowValue = 0;
   double   fastSlowSignalValue = 0;
   datetime convertedTime;
   datetime tempTimeArray_TF2[];



   barsTimeFrameCount = Bars(Symbol(), InpTimeframe) - 1;
   if(barsTimeFrameCount < InpSlowMAPeriod || pRatesTotal < InpSlowMAPeriod)
      return(0);

   calculatedBars = BarsCalculated(ExtFastMaHandle);
   if(calculatedBars < barsTimeFrameCount) {
      Print("Not all data of ExtFastMaHandle is calculated (", calculatedBars, " bars ", barsTimeFrameCount, "). Error ", GetLastError());
      return(0);
   }

   calculatedBars = BarsCalculated(ExtMiddleMaHandle);
   if(calculatedBars < barsTimeFrameCount) {
      Print("Not all data of ExtMiddleMaHandle is calculated (", calculatedBars, " bars). Error ", GetLastError());
      return(0);
   }

   calculatedBars = BarsCalculated(ExtSlowMaHandle);
   if(calculatedBars < barsTimeFrameCount) {
      Print("Not all data of ExtSlowMaHandle is calculated (", calculatedBars, " bars). Error ", GetLastError());
      return(0);
   }

   if(pPrevCalculated == 0) {
      start = 0;
   } else {
      start = pPrevCalculated - 1;
   }

   for(i = start; i < pRatesTotal && !IsStopped(); i++) {

// wird nicht nebuntzt!
//      if(periodRatio > 0) {
//         currentCandle = (int)MathRound((pRatesTotal - i) / periodRatio);
//      } else {
//         currentCandle = pRatesTotal - i;
//      }

      convertedTime = pTime[i];

      CopyTime(NULL, InpTimeframe, calculatedBars - 1, 1, tempTimeArray_TF2);

      if(convertedTime < tempTimeArray_TF2[0]) {
         ExtFastMaBuffer[i] = EMPTY_VALUE;
         ExtMiddleMaBuffer[i] = EMPTY_VALUE;
         ExtSlowMaBuffer[i] = EMPTY_VALUE;
         continue;
      }

      if(i > 0) {
         if(CopyBuffer(ExtFastMaHandle, 0, convertedTime, 1, ExtFastMaTmpArray) <= 0) {
            if(ShowErrorMessages) Print("Getting FastMa failed! Error", GetLastError());
            return(0);
         } else {
            ExtFastMaBuffer[i] = ExtFastMaTmpArray[0];
         }

         if(CopyBuffer(ExtMiddleMaHandle, 0, convertedTime, 1, ExtMiddleMaTmpArray) <= 0) {
            if(ShowErrorMessages) Print("Getting MiddleMa failed! Error", GetLastError());
            return(0);
         } else {
            ExtMiddleMaBuffer[i] = ExtMiddleMaTmpArray[0];
         }

         if(CopyBuffer(ExtSlowMaHandle, 0, convertedTime, 1, ExtSlowMaTmpArray) <= 0) {
            if(ShowErrorMessages) Print("Getting SlowMa failed! Error", GetLastError());
            return(0);
         } else {
            ExtSlowMaBuffer[i] = ExtSlowMaTmpArray[0];
         }

         // fastSlow
         FastSlowBuffer[i] = EMPTY_VALUE;
         if(ExtSlowMaBuffer[i] != EMPTY_VALUE) FastSlowBuffer[i] = (pClose[i] - ExtSlowMaBuffer[i]) / Point();

         //Print("----------------------------------------------------------");
         //Print("Close: " + pClose[i]);
         //Print("ExtSlowMaBuffer[i]: " + ExtSlowMaBuffer[i]);
         ////Print("EMPTY_VALUE: " + EMPTY_VALUE);
         //Print("FastSlowBuffer[i]: " + FastSlowBuffer[i]);

         // fastSlowSignal
         if(FastSlowBuffer[i] != EMPTY_VALUE) {
            if(i > InpSlowMAPeriod + InpFastMAPeriod) {
               double first_value = 0;
               for(int periodId = 0; periodId < InpFastMAPeriod; periodId++) {
                  first_value += FastSlowBuffer[i - periodId];
               }
               FastSlowSignalBuffer[i] = first_value / InpFastMAPeriod;
            }


            // GWL
            if(InpTimeframe != ChartPeriod()) {
               // fastSlowSignalColor
               int fastSlowSignalOpositeTrendMA = 5;
               double minDynamicOpositeTrendPerPeriod = 0.5;
               int fastSlowSignalTrendMA = 2;
               double minDynamicTrendPerPeriod = 5;

               if(i > InpFastMAPeriod + fastSlowSignalOpositeTrendMA) {

                  FastSlowColorBuffer[i] = ROTATION_AREA;
                  FastSlowSignalColorBuffer[i] = ROTATION_AREA;

                  // OPOSITE UP
                  if((FastSlowSignalBuffer[i - fastSlowSignalOpositeTrendMA] - FastSlowSignalBuffer[i - 1]) < (fastSlowSignalOpositeTrendMA * minDynamicOpositeTrendPerPeriod)) {
                     FastSlowColorBuffer[i] = UP_TREND;
                     FastSlowSignalColorBuffer[i] = UP_TREND;
                  }

                  // TREND DOWN
                  if(
                     (FastSlowSignalBuffer[i - fastSlowSignalTrendMA] - FastSlowSignalBuffer[i]) > (fastSlowSignalTrendMA * minDynamicTrendPerPeriod)
                     || (FastSlowBuffer[i - 1] > FastSlowBuffer[i] && FastSlowBuffer[i - 2] > FastSlowBuffer[i - 1] && FastSlowBuffer[i - 3] > FastSlowBuffer[i - 2] && FastSlowBuffer[i - 4] > FastSlowBuffer[i - 3])
                  ) {
                     FastSlowColorBuffer[i] = DOWN_TREND;
                     FastSlowSignalColorBuffer[i] = DOWN_TREND;
                  }


                  // UP_NORMAL
                  //if(FastSlowSignalBuffer[i - fastSlowSignalMA] < FastSlowSignalBuffer[i]) {
                  //   FastSlowColorBuffer[i] = UP_TREND;
                  //   FastSlowSignalColorBuffer[i] = UP_TREND;
                  //}
                  //// DOWN_NORMAL
                  //if(FastSlowSignalBuffer[i - fastSlowSignalMA] > FastSlowSignalBuffer[i]) {
                  //   FastSlowColorBuffer[i] = DOWN_TREND;
                  //   FastSlowSignalColorBuffer[i] = DOWN_TREND;
                  //}

                  // ROTATION_AREA
                  //if(MathMax(FastSlowSignalBuffer[i - fastSlowSignalMA], FastSlowSignalBuffer[i]) - MathMin(FastSlowSignalBuffer[i - fastSlowSignalMA], FastSlowSignalBuffer[i]) < (fastSlowSignalMA * minDynamicPerPeriod)) {
                  //   FastSlowColorBuffer[i] = ROTATION_AREA;
                  //   FastSlowSignalColorBuffer[i] = ROTATION_AREA;
                  //}
                  //if(FastSlowSignalColorBuffer[i] == UP_TREND && FastSlowSignalBuffer[i] > FastSlowBuffer[i]) {
                  //   FastSlowColorBuffer[i] = ROTATION_AREA;
                  //   FastSlowSignalColorBuffer[i] = ROTATION_AREA;
                  //}
               }
            }

            // SGL
            if(InpTimeframe == ChartPeriod()) {
               // fastSlowSignalColor
               int fastSlowSignalMA = 3;
               double minDynamicPerPeriod = 3;
               if(i > InpFastMAPeriod + fastSlowSignalMA) {

                  FastSlowColorBuffer[i] = ROTATION_AREA;
                  FastSlowSignalColorBuffer[i] = ROTATION_AREA;

                  // ROTATION_AREA
                  //if(MathMax(FastSlowSignalBuffer[i - fastSlowSignalMA], FastSlowSignalBuffer[i]) - MathMin(FastSlowSignalBuffer[i - fastSlowSignalMA], FastSlowSignalBuffer[i]) < (fastSlowSignalMA * minDynamicPerPeriod)) {
                  //   FastSlowColorBuffer[i] = ROTATION_AREA;
                  //   FastSlowSignalColorBuffer[i] = ROTATION_AREA;
                  //}
                  //if(FastSlowSignalColorBuffer[i] == UP_TREND && FastSlowSignalBuffer[i] > FastSlowBuffer[i]) {
                  //   FastSlowColorBuffer[i] = ROTATION_AREA;
                  //   FastSlowSignalColorBuffer[i] = ROTATION_AREA;
                  //}

                  //// UP_NORMAL
                  //if(FastSlowSignalBuffer[i - fastSlowSignalMA] < FastSlowSignalBuffer[i]) {
                  //   FastSlowColorBuffer[i] = UP_TREND;
                  //   FastSlowSignalColorBuffer[i] = UP_TREND;
                  //}


                  // DOWN_NORMAL
                  if(
                     FastSlowSignalBuffer[i - fastSlowSignalMA] > FastSlowSignalBuffer[i]
//                     || (FastSlowBuffer[i - 1] > FastSlowBuffer[i] && FastSlowBuffer[i - 2] > FastSlowBuffer[i - 1] && FastSlowBuffer[i - 3] > FastSlowBuffer[i - 2] && FastSlowBuffer[i - 4] > FastSlowBuffer[i - 3])
                     || (FastSlowBuffer[i - 1] > FastSlowBuffer[i] && FastSlowBuffer[i - 2] > FastSlowBuffer[i - 1] && FastSlowBuffer[i - 3] > FastSlowBuffer[i - 2])
                  ) {
                     FastSlowColorBuffer[i] = DOWN_TREND;
                     FastSlowSignalColorBuffer[i] = DOWN_TREND;

                  }

                  if(
                     FastSlowSignalBuffer[i - fastSlowSignalMA] < FastSlowSignalBuffer[i]
                     || (FastSlowBuffer[i - 1] < FastSlowBuffer[i] && FastSlowBuffer[i - 2] < FastSlowBuffer[i - 1] && FastSlowBuffer[i - 3] < FastSlowBuffer[i - 2] && FastSlowBuffer[i - 4] < FastSlowBuffer[i - 3])
                  ) {
                     FastSlowColorBuffer[i] = UP_TREND;
                     FastSlowSignalColorBuffer[i] = UP_TREND;
                     sellIsTradeable = false;
                  }
               }
            }
         }

//         if(FastSlowBuffer[i] > 0) {
//
//            sellSessionMaxDynamic = 0;
//
//            fastSlowValue = FastSlowBuffer[i];
//            fastSlowSignalValue = FastSlowSignalBuffer[i];
//
//            if(fastSlowValue < InpMinDynamic) FastSlowColorBuffer[i] = 1;
//            if(fastSlowValue > InpMinDynamic && fastSlowValue < InpMaxDynamic) FastSlowColorBuffer[i] = 2;
//            if(fastSlowValue > InpMaxDynamic) FastSlowColorBuffer[i] = 3;
//
//            if(fastSlowValue < fastSlowSignalValue) {
//               FastSlowColorBuffer[i] = 0;
//            }
//
//            for(int barShiftId = 0; barShiftId < InpCandleCountFastSlowDynamic; barShiftId++) {
//               if(i - barShiftId > 0) {
//                  if(FastSlowBuffer[i - barShiftId] > localHighestHighDynamic) {
//                     localHighestHighDynamic = FastSlowBuffer[i - barShiftId];
//                     localHighestHighIndex = i - barShiftId;
//                  }
//               }
//            }
//
//            double localBuyDynamic;
//            if(i > localHighestHighIndex) {
//               localBuyDynamic = (FastSlowBuffer[i] - localHighestHighDynamic) / (i - localHighestHighIndex);
//            } else {
//               localBuyDynamic = FastSlowBuffer[i] - localHighestHighDynamic;
//            }
//
//            if(localBuyDynamic < InpFastSlowDynamic * -1) {
//               FastSlowColorBuffer[i] = 5;
//            }
//
//            if(fastSlowValue > buySessionMaxDynamic) {
//               buySessionMaxDynamic = fastSlowValue;
//            }
//         }
//
//         if(FastSlowBuffer[i] < 0) {
//
//            buySessionMaxDynamic = 0;
//
//            fastSlowValue = FastSlowBuffer[i] * -1;
//            fastSlowSignalValue = FastSlowSignalBuffer[i] * -1;
//
//            if(fastSlowValue < InpMinDynamic) FastSlowColorBuffer[i] = 4;
//            if(fastSlowValue > InpMinDynamic && fastSlowValue < InpMaxDynamic) FastSlowColorBuffer[i] = 5;
//            if(fastSlowValue > InpMaxDynamic) FastSlowColorBuffer[i] = 6;
//
//            if(fastSlowValue < fastSlowSignalValue) {
//               FastSlowColorBuffer[i] = 0;
//            }
//
//            for(int barShiftId = 0; barShiftId < InpCandleCountFastSlowDynamic; barShiftId++) {
//               if(i - barShiftId > 0) {
//                  if(FastSlowBuffer[i - barShiftId] < localLowestLowDynamic) {
//                     localLowestLowDynamic = FastSlowBuffer[i - barShiftId];
//                     localLowestLowIndex = i - barShiftId;
//                  }
//               }
//            }
//
//            double localSellDynamic;
//            if(i > localLowestLowIndex) {
//               localSellDynamic = (FastSlowBuffer[i] - localLowestLowDynamic) / (i - localLowestLowIndex);
//            } else {
//               localSellDynamic = FastSlowBuffer[i] - localLowestLowDynamic;
//            }
//
//            if(localSellDynamic > InpFastSlowDynamic) {
//               FastSlowColorBuffer[i] = 2;
//            }
//
//            if(fastSlowValue > sellSessionMaxDynamic) {
//               sellSessionMaxDynamic = fastSlowValue;
//            }
//         }



         // middleSlow
         MiddleSlowBuffer[i] = (ExtMiddleMaBuffer[i] - ExtSlowMaBuffer[i]) / Point();

//         if(ExtMiddleMaBuffer[i] > middleHighestHigh) {
//            middleHighestHigh = ExtMiddleMaBuffer[i];
//            middleHighestHighIndex = i;
//            middleHighestHighTime = time[i];
//            ObjectMove(0, MIDDLE_CROSSED_SLOW_FROM_BELOW, 0, middleHighestHighTime, 0);
//            //middleLowestLow = 100 / Point();
//         }
//
//         if(ExtMiddleMaBuffer[i] < middleLowestLow) {
//            middleLowestLow = ExtMiddleMaBuffer[i];
//            middleLowestLowIndex = i;
//            middleLowestLowTime = time[i];
//            ObjectMove(0, MIDDLE_CROSSED_SLOW_FROM_ABOVE, 0, middleLowestLowTime, 0);
//            //middleHighestHigh = 0;
//         }
//
//         if(fastLineCrossedSlowLineFromBelow(ExtMiddleMaBuffer[i - 1], ExtMiddleMaBuffer[i], ExtSlowMaBuffer[i - 1], ExtSlowMaBuffer[i]) == true) {
//            middleCrossedSlowFromBelowValue = ExtMiddleMaBuffer[i];
//            middleCrossedSlowFromBelowIndex = i;
//            middleHighestHigh = 0;
//            //middleHighestHighIndex = 90000000;
//         }
//
//         if(fastLineCrossedSlowLineFromAbove(ExtMiddleMaBuffer[i - 1], ExtMiddleMaBuffer[i], ExtSlowMaBuffer[i - 1], ExtSlowMaBuffer[i]) == true) {
//            middleCrossedSlowFromAboveValue = ExtMiddleMaBuffer[i];
//            middleCrossedSlowFromAboveIndex = i;
//            middleLowestLow = 100 / Point();
//            //middleHighestHighIndex = 90000000;
//         }
//



         //fastSelf
         //if(fastLineCrossedSlowLineFromBelow(ExtFastMaBuffer[i - 1], ExtFastMaBuffer[i], ExtSlowMaBuffer[i - 1], ExtSlowMaBuffer[i]) == true) {
         //   fastCrossedSlowFromBelowValue = ExtSlowMaBuffer[i];
         //   fastCrossedSlowFromBelowIndex = i;
         //   fastCrossedSlowFromBelowTime = time[i];
         //}
         //if(i > fastCrossedSlowFromBelowIndex) {
         //   FastSelfBuffer[i] = (ExtFastMaBuffer[i] - fastCrossedSlowFromBelowValue) / (i - fastCrossedSlowFromBelowIndex) / Point();
         //} else {
         //   FastSelfBuffer[i] = 0;
         //}
//
//         // UP_TREND
//         if(i > middleLowestLowIndex && ExtFastMaBuffer[i] > ExtSlowMaBuffer[i] && middleLowestLow < 100 / Point()) {
//            MiddleSelfBuffer[i] = (ExtMiddleMaBuffer[i] - middleLowestLow) / (i - middleLowestLowIndex) / Point();
//            //SlowSelfBuffer[i] = 0; //(ExtSlowMaBuffer[i] - middleCrossedSlowFromBelowValue) / (i - middleCrossedSlowFromBelowIndex) / Point();
//
//            //middleLowestLow = 100 / Point();
//         } else {
//            //MiddleSelfBuffer[i] = 0;
//            //SlowSelfBuffer[i] = 0;
//         }
//
//         // DOWN_TREND
//         if(i > middleHighestHighIndex && ExtFastMaBuffer[i] < ExtSlowMaBuffer[i] && middleHighestHigh > 0) {
//            MiddleSelfBuffer[i] = (ExtMiddleMaBuffer[i] - middleHighestHigh) / (i - middleHighestHighIndex) / Point();
//            //SlowSelfBuffer[i] = 0; //(ExtSlowMaBuffer[i] - middleCrossedSlowFromBelowValue) / (i - middleCrossedSlowFromBelowIndex) / Point();
//            //middleHighestHigh = 0;
//         } else {
//            //MiddleSelfBuffer[i] = 0;
//            //SlowSelfBuffer[i] = 0;
//         }

//         Print("middleLowestLow: " + middleLowestLow + " // " + middleLowestLowIndex + " // " + middleLowestLowTime);
//         Print("middleHighestHigh: " + middleHighestHigh + " // " + middleHighestHighIndex + " // " + middleHighestHighTime);



      }

   }

   return(pRatesTotal);
}
//+------------------------------------------------------------------+

bool fastLineCrossedSlowLineFromBelow(double lastFastLine, double currentFastLine, double lastSlowLine, double currentSlowLine) {

   bool signal = false;

   if(lastFastLine <= lastSlowLine && currentFastLine > currentSlowLine) {
      signal = true;
   }

   return(signal);
}

bool fastLineCrossedSlowLineFromAbove(double lastFastLine, double currentFastLine, double lastSlowLine, double currentSlowLine) {

   bool signal = false;

   if(lastFastLine >= lastSlowLine && currentFastLine < currentSlowLine) {
      signal = true;
   }

   return(signal);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
