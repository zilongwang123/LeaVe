module prod
 (
   input XCLK,
   input XRES,
   input UART_RXD
 );  
   wire       XRES;
   wire       UART_TXDLeft;
   wire       UART_TXDRight;

   wire       UART_RXDLeft;
   wire       UART_RXDRight;

   wire       [3:0] LEDLeft;
   wire       [3:0] LEDRight;


   wire       [3:0] DEBUGLeft;
   wire       [3:0] DEBUGRight;



//**Wire declarations**//
//**Init register**//
//**Stuttering Signal**//
//**Self-composed modules**//
//**Initial state**//
//**State invariants**//
//**Verification conditions**//
 endmodule