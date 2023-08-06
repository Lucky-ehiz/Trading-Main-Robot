//+------------------------------------------------------------------+
//|                                            Spartan BoomCrash.mq5 |
//|                    Copyright 2022, MetaQuotes Ltd.Ehizojie Lucky |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+


#define ACCOUNT 20978334
#define EXPIRY_YEAR 0
#define EXPIRY_MONTH 0
#define EXPIRY_DAY 0


#property indicator_chart_window

#property indicator_buffers 2
#property indicator_plots   2
#property indicator_color1 clrYellow
#property indicator_color2 clrYellow

enum signal 
{
   signal_both, // Both
   signal_buy,  // Only Buy   
   signal_sell,  // Only Sell
};

double BuySignal[];
double SellSignal[];
double RSIValues[];

input  signal  SignalType        = signal_both;    // Type of signal
input  int 		RSIPeriod			= 14;					// Period
input  ENUM_APPLIED_PRICE RSIApp = PRICE_CLOSE;	   // Applied price
input  double  BuyLvl            = 4.13;           // Buy level
input  double  SellLvl           = 97.80;          // Sell level
input  bool    UseAlert          = false;          // Pop-up Alerts?
input  bool    UseMobile         = false;          // Mobile Notifications?
input  bool    UseEmail          = false;          // Email Messages?

int Minimum;
int ArrowSize = 3;
datetime ExpiryTime = 0;

void iiRSI(int shift)
{
   static int handle = iRSI(Symbol(),PERIOD_CURRENT,RSIPeriod,RSIApp);
   CopyBuffer(handle,0,0,shift+1,RSIValues);
}

void SendAlert(string alert, string email, string mobile)
{
   if(alert!=NULL)
      Alert(alert);
   if(email!=NULL)
      SendMail(NULL,email);
   if(mobile!=NULL)
      SendNotification(mobile);
}

int OnInit()
{
   if(AccountInfoInteger(ACCOUNT_LOGIN) != ACCOUNT && ACCOUNT != 0)
   {
      Alert("Account not allowed for this indicator");
      return INIT_FAILED;
   }
   
   int year = EXPIRY_YEAR;
   if(year > 0)
   {
      int month = EXPIRY_MONTH;
      int day = EXPIRY_DAY;
      MqlDateTime expiry_struct;
      ZeroMemory(expiry_struct);
      expiry_struct.year = year;
      expiry_struct.mon = month;
      expiry_struct.day = day;
      ExpiryTime = StructToTime(expiry_struct);
   }
   
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
   
   SetIndexBuffer(0,BuySignal,INDICATOR_DATA);
   SetIndexBuffer(1,SellSignal,INDICATOR_DATA);
   
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_ARROW);
   PlotIndexSetInteger(0,PLOT_ARROW,241);
   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,ArrowSize);
   PlotIndexSetString(0,PLOT_LABEL,"Buy Signal");
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   
   PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_ARROW);
   PlotIndexSetInteger(1,PLOT_ARROW,242);
   PlotIndexSetInteger(1,PLOT_LINE_WIDTH,ArrowSize);
   PlotIndexSetString(1,PLOT_LABEL,"Sell Signal");
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
   
   
   ArraySetAsSeries(BuySignal,true);
   ArraySetAsSeries(SellSignal,true);
   ArraySetAsSeries(RSIValues,true);
   
   Minimum = RSIApp + 2;
   
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(ExpiryTime > 0)
   {
      if(TimeCurrent() > ExpiryTime)
      {
         static bool informed = false;
         if(!informed)
         {
            Alert("Indicator has expired");
            informed = true;
         }
         return 0;
      }
   }
   
   if(prev_calculated >= rates_total)
      return(rates_total);
   
   static int i;
   i = rates_total-prev_calculated;
   if(i>rates_total-Minimum)
      i = rates_total-Minimum;
   
   if(i<=0)
      return rates_total;
      
   if(prev_calculated == 0)
   {
      for(int j=i+1;j<rates_total;j++)
      {
         BuySignal[i] = 0.0;
         SellSignal[i] = 0.0;
      }   
   }   
      
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(time,true);    
   
   iiRSI(i+1);
   for(;i>0;i--)
   {
      if(SignalType != signal_sell && RSIValues[i] < BuyLvl && RSIValues[i+1] > BuyLvl)
      {
         BuySignal[i] = low[i]-(low[i]*0.003);
         if(i == 1)
         {
            ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)Period();
      	   string message = Symbol()+": "+EnumToString(tf)+" Buy signal";
            SendAlert((UseAlert)?message:NULL,(UseEmail)?message:NULL,(UseMobile)?message:NULL);
         }
      }
      else
         BuySignal[i] = 0.0;   
      
      if(SignalType != signal_buy && RSIValues[i] > SellLvl && RSIValues[i+1] < SellLvl)
      {
         SellSignal[i] = high[i]+(high[i]*0.003);
         if(i == 1)
         {
            ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)Period();
      	   string message = Symbol()+": "+EnumToString(tf)+" Sell signal";
            SendAlert((UseAlert)?message:NULL,(UseEmail)?message:NULL,(UseMobile)?message:NULL);
         }
      }
      else
         SellSignal[i] = 0.0;   
   }
   
   
   return(rates_total);
}
