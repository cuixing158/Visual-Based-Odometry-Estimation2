
#include "test1.h"

std::vector<string> getImageNames(const char* imgList)
{
    std::vector<string> images;
    string line,imageFile;
    imageFile = imgList; 
    ifstream fid(imageFile, std::ios::in);

    while (std::getline(fid, line)) {
        images.push_back(line);
    }
    fid.close();

    // test outpu file
    ofstream fid2("out.txt");
    fid2<< "imageFile:" << imageFile << '\n';
    fid2<<"--------images.size():"<<images.size()<<"-----"<<std::endl;
    for(int i{0};i<images.size();i++){
        fid2<<"image"<<","<<images[i]<<std::endl;
    }
    fid2.close();
    return images;
}

void getImage(const unsigned char inImage[20000],unsigned char outImage[20000])
{
    for (int i{0}; i < 20000; i++) {
        int i1;
        i1 = static_cast<int>(inImage[i] + 2U);
        if (static_cast<unsigned int>(i1) > 255U) {
            i1 = 255;
        }
        outImage[i] = static_cast<unsigned char>(i1);
    }
}