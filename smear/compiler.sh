#!/bin/bash 
## FUNCTION:
## Compila 
RED='\e[0;31m'
BLUE='\e[0;34m'
CYAN='\e[0;36m'
GREEN='\e[0;32m'
YELLOW='\e[1;33m'
NC='\e[0m' # No Color 
 dir=$PWD
 if [ "$#" -eq 0 ]
   then 
  printf " \n"
  printf " Usage [${GREEN}Option${NC}]:\n "
  printf "\t${GREEN}3264${NC}        : "
  printf "${CYAN}Compile 32 and 64 bits${NC}(xeon,itanium and quad)\n" 
  printf "\t${GREEN}xeon${NC}        :" 
  printf "${CYAN} Compile 32 ${NC} xeon\n " 
  printf "\t${GREEN}itanium  ${NC}   : ${CYAN}Compile 64${NC} itanium\n"
  printf "\t${GREEN}quad  ${NC}      : ${CYAN}Compile 64${NC} quad\n"
  printf "\t${GREEN}hexa  ${NC}      : ${CYAN}Compile 64${NC} hexa\n"
  printf " \n"
  printf "\texample: ./`basename $0` 3264 \n"
  printf "\t${RED}Stoping right now ...${NC}\n" 
  printf " \n"
  exit 1 
 fi 

  if [ ! -e Makefile ];then 
  printf "\tThere is not FILE: Makefile ....\n"
  printf "\t${RED}Stoping right now ...${NC}\n" 
  exit 1
  fi 

  if [ $1 == '3264' ] ||[ $1 == '6432' ]; then
  printf "\t${GREEN}Compiling 64 and 32 bits ${NC} \n"
  make clean >> /dev/null
  rsh -n itanium01 "cd $dir; make"
  make clean >> /dev/null
 printf "\t${BLUE}Check for errors....${NC}\n "
 printf "\t${BLUE}you are going to compile in 32 bits...${NC}\n" 
 printf "\t${BLUE}Press any key to continue...or Ctrl C to kill${NC}\n"
  read -p " "
  make
  make clean >> /dev/null 
  printf " \n"
  printf "\t${BLUE}Check for errors....${NC}\n "
 printf "\t${BLUE}you are going to compile in 64 bits...QUAD${NC}\n" 
 printf "\t${BLUE}Press any key to continue...or Ctrl C to kill${NC}\n"
  read -p " "
     make clean >> /dev/null
     rsh  quad01 "cd $dir; make"
     make clean >> /dev/null
  fi

 if [ $1 == 'xeon' ];then 
    printf "\t${GREEN}compiling 32 xeon ${NC}  \n"
    make clean >> /dev/null
    make 
    make clean >> /dev/null
    printf " \n"
fi
   if [ $1 == 'itanium' ];then
     printf "\t${GREEN}compiling 64 itanium ${NC} \n"
     make clean >> /dev/null
     rsh  itanium01 "cd $dir; make"
     make clean >> /dev/null
    fi

   if [ $1 == 'quad' ];then
     printf "\t${GREEN}compiling 64 quad ${NC} \n"
     make clean >> /dev/null
     rsh  quad01 "cd $dir; make"
     make clean >> /dev/null
    fi

   if [ $1 == 'hexa' ];then
     printf "\t${GREEN}compiling hexa ${NC} \n"
     make clean >> /dev/null
     rsh  quad01 "cd $dir; make"
     make clean >> /dev/null
    fi

