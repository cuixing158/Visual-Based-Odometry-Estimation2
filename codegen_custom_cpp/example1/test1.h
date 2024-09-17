#ifndef _TEST_H_
#define _TEST_H_

#include<iostream>
#include<string>
#include<fstream>
#include<vector>

using namespace std;

std::vector<string> getImageNames(const char* imgList);

void getImage(const unsigned char inImage[20000],unsigned char outImage[20000]);

#endif