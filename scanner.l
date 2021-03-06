/* File:  scanner.l
 * ----------------
 * Lex inupt file to generate the scanner for the compiler.
 */

%{

/* The text within this first region delimited by %{ and %} is assumed to
 * be C/C++ code and will be copied verbatim to the lex.yy.c file ahead
 * of the definitions of the yylex() function. Add other header file inclusions
 * or C++ variable declarations/prototypes that are needed by your code here.
 */

#include <string.h>
#include "scanner.h"
#include "utility.h" // for PrintDebug()
#include "errors.h"

/* Global variable: yylval
 * -----------------------
 * This global variable is how we get attribute information about the token
 * just scanned to the client. The scanner sets the global variable
 * appropriately and since it's global the client can just read it.  In the
 * future, this variable will be declared for us in the y.tab.c file
 * produced by Yacc, but for now, we declare it manually.
 */
YYSTYPE yylval;  // manually declared for pp1, later Yacc provides

/* Global variable: yylloc
 * -----------------------
 * This global variable is how we get position information about the token
 * just scanned to the client. (Operates similarly to yylval above)
 */
struct yyltype yylloc; // manually dclared for pp1, later Yacc provides

/* Macro: YY_USER_ACTION 
 * ---------------------
 * This flex built-in macro can be defined to provide an action which is
 * always executed prior to any matched rule's action. Basically, it is
 * a way of having a piece of code common to all actions factored out to
 * this routine.  We already defined it for you and left the empty
 * function DoBeforeEachAction ready for your use as needed. It will
 * be called once for each pattern scanned from the file, before
 * executing its action.
 */
static void DoBeforeEachAction(); 
#define YY_USER_ACTION DoBeforeEachAction();
int line_no, col_no;

%}

 /* The section before the first %% is the Definitions section of the lex
  * input file. Here is where you set options for the scanner, define lex
  * states, and can set up definitions to give names to regular expressions
  * as a simple substitution mechanism that allows for more readable
  * entries in the Rules section later. 
  */

DIGIT           [0-9]
Identifier      [a-zA-Z][a-zA-Z0-9_]{1,}
Quote           ["]
HEX             0X|0x
HEX_DIGIT       [0-9]|[a-fA-F]
Ident1	[a-zA-Z]
Ident2	[a-zA-Z0-9_]
Ident3	[a-zA-Z0-9]
Ident4	[_]

%%

"\n"	{
			col_no=1; 
			line_no++; 
			//printf("line no %d\n", line_no);
		}
" "		{
			/*do nothing*/ 
			//printf("space here\n");
		}
"/*"[^"/*"]*"*/"	{/*multi line comments*/}
"//"[^\n]*	{/*anything starting with // and followed by a non end of line char is taken as a single line comment*/}

	/*--bool constant--*/
true|false      {
					if(yytext[0]=='t')
						yylval.boolConstant = true;
					else 
						yylval.boolConstant = false;
					return T_BoolConstant;
				} 

	/*--keywords--*/
void  return T_Void;
int   return T_Int;
double return T_Double;
bool return T_Bool;
string return T_String;
class return T_Class;
null return T_Null;

	/*--2 character operator--*/
"<=" return T_LessEqual;
">=" return T_GreaterEqual;
"==" return T_Equal;
"!=" return T_NotEqual;
"&&" return T_And;
"||" return T_Or;

	/*--keywords--*/
while return T_While;
for return T_For;
if return T_If;
else return T_Else;
return return T_Return;
break return T_Break;
extends return T_Extends;
this return T_This;
implements return T_Implements;
interface return T_Interface;
New return T_New;
NewArray return T_NewArray;

\"[^\n]*\"		{	//{Quote}.+{Quote}
						yylval.stringConstant = strdup(yytext);
						return T_StringConstant;
						//printf( "A string constant: %s, size is: %d, cols %d to %d line_no %d\n", yytext,strlen(yytext), yylloc.first_column, yylloc.last_column, yylloc.first_line );
					}
\"[^\n|^\"]*	{
					ReportError::UntermString(&yylloc, yytext);
					//line_no++; col_no = 1;
				}


{Identifier}|[a-zA-Z]    {	//{Identifier}
					strncpy(yylval.identifier, yytext, MaxIdentLen+1);
					if(strlen(yytext) > MaxIdentLen)
					{
						ReportError::LongIdentifier(&yylloc, yytext);
						yylval.identifier[MaxIdentLen]='\0';
					}
					else
					{
						strncpy(yylval.identifier, yytext, MaxIdentLen+1);
						yylval.identifier[strlen(yytext)]='\0';
					}
						
					//printf("len %d max %d\n", strlen(yytext), MaxIdentLen);
  					return T_Identifier;
                }

"+"|"-"|"*"|"/"|"%"|"<"|">"|"="|"!"|";"|","|"."|"["|"]"|"("|")"|"{"|"}"		{
																				return int(yytext[0]);
															                }

{DIGIT}+        {
                  yylval.integerConstant = atoi(yytext);
                  return T_IntConstant;
                }

{DIGIT}+"."{DIGIT}*     {
                          yylval.doubleConstant = atof(yytext);
                          return T_DoubleConstant;
                        }

{DIGIT}+"."{DIGIT}*[eE]"+"{DIGIT}+      {
                                          yylval.doubleConstant = atof(yytext);
                                          return T_DoubleConstant;
                                        }



{HEX}{HEX_DIGIT}+   {
						yylval.integerConstant = strtol(yytext,NULL,16);
						return T_IntConstant;
					}

.		{
			ReportError::UnrecogChar(&yylloc, yytext[0]);
		}
             /* BEGIN RULES SECTION */
 /* All patterns and actions should be placed between the start and stop
  * %% markers which delimit the Rules section. 
  */ 

%%
/* The closing %% above marks the end of the Rules section and the beginning
 * of the User Subroutines section. All text from here to the end of the
 * file is copied verbatim to the end of the generated lex.yy.c file.
 * This section is where you put definitions of helper functions.
 */


/* Function: InitScanner
 * ---------------------
 * This function will be called before any calls to yylex().  It is designed
 * to give you an opportunity to do anything that must be done to initialize
 * the scanner (set global variables, configure starting state, etc.). One
 * thing it already does for you is assign the value of the global variable
 * yy_flex_debug that controls whether flex prints debugging information
 * about each token and what rule was matched. If set to false, no information
 * is printed. Setting it to true will give you a running trail that might
 * be helpful when debugging your scanner. Please be sure the variable is
 * set to false when submitting your final version.
 */
void InitScanner()
{
    PrintDebug("lex", "Initializing scanner");
    yy_flex_debug = false;
    //Initialize the line and col no variables here
    line_no = 1;
    col_no = 1;
}


/* Function: DoBeforeEachAction()
 * ------------------------------
 * This function is installed as the YY_USER_ACTION. This is a place
 * to group code common to all actions.
 */
static void DoBeforeEachAction()
{

  //The line number, first_column and last_column are updated here
  //printf("len of yytext is %d\n", strlen(yytext));

  yylloc.first_line = line_no;
  yylloc.first_column = col_no;
  col_no = col_no + strlen(yytext);
  yylloc.last_column = col_no -1;
}
