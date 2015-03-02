import com.jhlabs.image.PixelUtils;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

public class iterativeAlpha {


    public static void main(String args[])
    {
        // the numbder of alpha steps per image
        float numNewImages = 30;

        // the names of the images to be altered
        String[] capuchinNames = {"Bailey", "Gabe", "Gambit", "Griffin", "Lexi", "Liam", "Lily", "Logan", "Nala", "Nykema", "Widget", "Wren"};
        String[] macaqueNames  = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"};

        String inputPath  = "C:\\Users\\Jim\\Code\\BCD\\HillaryDissertation\\Images\\";
        String outputPath = "C:\\Users\\Jim\\IdeaProjects\\AdjustAlpha\\";


        for(int faceNumber = 0; faceNumber < capuchinNames.length + macaqueNames.length; ++faceNumber)
        {
            BufferedImage src = null;
            String inputfile;
            String destfile;
            String fileExtension = ".png:";
            File currentFile;


            if(faceNumber / 12 < 1)
            {
                int fileName = faceNumber % 12;

                currentFile = new File(capuchinNames[faceNumber]);
                if(!currentFile.exists())
                {
                    currentFile.mkdir();
                }
                else
                {
                    currentFile.delete();
                    currentFile.mkdir();
                }

                inputfile = inputPath + "Capuchins\\" + capuchinNames[faceNumber];
                destfile = currentFile.getAbsolutePath() + "\\" + capuchinNames[fileName];
            }
            else
            {
                int fileName = faceNumber % 12;

                currentFile = new File(macaqueNames[fileName]);
                if(!currentFile.exists())
                {
                    currentFile.mkdir();
                }
                else
                {
                    currentFile.delete();
                    currentFile.mkdir();
                }

                inputfile = inputPath + "Macaques\\" + macaqueNames[fileName];
                destfile = currentFile.getAbsolutePath() + "\\" + macaqueNames[fileName];
            }

            try {
                src = ImageIO.read(new File(inputfile + ".png"));
            } catch (IOException e) {
            }

            int width = src.getWidth();
            int height = src.getHeight();
            BufferedImage dst = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);

            for (int j = 0; j < numNewImages; ++j) {

                float alpha = (j + 1) / numNewImages;

                Alpha(src, dst, alpha);

                String currentDestFile = destfile;

                currentDestFile += "_";
                currentDestFile += j + 1;
//            currentDestFile += fileExtension;

                System.out.println(currentDestFile);

                src = dst;

                File outfile = new File(currentDestFile + ".png");
                try {
                    ImageIO.write(src, "png", outfile);
                } catch (IOException e) {
                }
            }
        }
    }


    public static void Alpha(BufferedImage src, BufferedImage dst, float alpha)
    {
        int width = src.getWidth();
        int height = src.getHeight();

        // a buffer that stores the destination image pixels
        int[] pixels = new int[width * height];

        // get the pixels of the source image
        src.getRGB(0, 0, width, height, pixels, 0, width);

        int i;
        int a, r, g, b;
        for(i = 0; i < width * height; i ++) {
            Color rgb = new Color(pixels[i]);
            a = rgb.getAlpha();
            r = rgb.getRed();
            g = rgb.getGreen();
            b = rgb.getBlue();

            a = PixelUtils.clamp((int)((float)a * alpha));

            pixels[i] = new Color(r, g, b, a).getRGB();
        }

        // write pixel values to the destination image
        dst.setRGB(0, 0, width, height, pixels, 0, width);
    }
}
