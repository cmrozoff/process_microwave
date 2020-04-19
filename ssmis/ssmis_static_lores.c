/*
Read SSMIS SDR files and write out text file for scan lines encompassing feature of interest.  In this case tropical cyclones.
Currently coded to ouput SSMIS sounder channels (3-5).

Aquired from Kim Richardson at NRL Monterey.  Modified by Derrick Herndon at Univ of Wisonsin CIMSS

01 Aug 2005  JT
15 Mar 2011 - modifed to output sounder channels versus the imager channels

Probably some lines in here that could be removed but will retain in case needed in the future.

Make note of endianness flag sm = 1 or 0 prior to compiling
*/

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <sys/param.h>
#include <errno.h>
#include <strings.h>
#include <sys/time.h>

#define SEC_REV 1.904	/* seconds per conical scan */
#define NSIMG 180	/* samples or "scenes" per imager scanline */
#define NSENV 90	/* samples per environmental scanline */
#define NSLAS 60	/* samples per LAS scanline */
#define NSUAS 30	/* samples per UAS scanline */

short sm=1;         /* byte swapping mode for little-end-in machines 1 = little endian.  1 = little endian  */
int swapbytes();
int rds(), rdf(), rdd();    /* routines for reading arrays */
int fd;

main(argc,argv)
int argc;
char *argv[];
{

  typedef struct {
    short sw_rev;
    char endian, fileid;
    int rev, year;
    short jday;
    char hour, min;
    short satid, nsdr;
    char spare1, spare2, spare3;
    char proc_stat_flags;
    int spare4;
  } rev_header_record;

  typedef struct {
    int syncword, year;
    short jday;
    char hour, min;
    int scan;
    char nscan_imager, nscan_enviro, nscan_las, nscan_uas;
    int start_scantime_imager[28];
    unsigned char scenecounts_imager[28];
    int start_scantime_enviro[24];
    unsigned char scenecounts_enviro[24];
    int start_scantime_las[8];
    unsigned char scenecounts_las[8];
    int start_scantime_uas[4];
    unsigned char scenecounts_uas[4];
    int spare[5];
  } scan_header_record;

  typedef struct {
    short latitude, longitude, scene;
    char surf, rain;
    short ch08, ch09, ch10, ch11, ch17, ch18;
  } imager_scene_record;

  typedef struct {
    short latitude, longitude, scene;
    char sea_ice, surf;
    short ch12, ch13, ch14, ch15, ch16;
    short ch15_5x5, ch16_5x5, ch17_5x5, ch18_5x5, ch17_5x4, ch18_5x4;
    char rain1, rain2;
    int edr_bitflags;
  } enviro_odd_scene_record;

  typedef struct {
    short latitude, longitude, scene;
    char sea_ice, surf;
    short ch12, ch13, ch14, ch15, ch16;
  } enviro_even_scene_record;

  typedef struct {
    short latitude, longitude;
    short ch01_3x3, ch02_3x3;
    short ch03_3x3, ch04_3x3;
    short ch05_3x3, ch06_3x3;
    short ch07_3x3, ch08_5x5;
    short ch09_5x5, ch10_5x5;
    short ch11_5x5, ch18_5x5;
    short ch24_3x3, height_1000mb;
    short surf;
    char las_tqflag, las_hqflag;
    short terrain, scene;
  } las_scene_record;

  typedef struct {
    short latitude, longitude;
    short ch19_6x6, ch20_6x6;
    short ch21_6x6, ch22_6x6;
    short ch23_6x6, ch24_6x6;
    short scene, uas_tqflag;
    int field, bdotk2;
  } uas_scene_record;

  rev_header_record rev;
  scan_header_record scan;
  imager_scene_record imager;
  enviro_odd_scene_record enviro_odd;
  enviro_even_scene_record enviro_even;
  las_scene_record las;
  uas_scene_record uas;

  char *inname=argv[1], *outname=argv[2];
  int i, i2, j, k, n, nscan0, nsdr=0, nscan_las=0, nscan_uas=0,nbytes=0, start[2], count[2];
  int nfiller;
  char filler_bytes[512];
  float tb, lat, lon;
  int start_scantime_imager=-1, start_scantime_enviro=-1, start_scantime_las=-1, start_scantime_uas=-1;
  double sec, sec_prev;
  int nlines;

  short *buf01, *buf02, *buf03, *buf04, *buf05, *buf06, *buf07;
  short *buf08, *buf09, *buf10, *buf11, *buf12, *buf13, *buf14;
  short *buf15, *buf16, *buf17, *buf18;
  short *buf19, *buf20, *buf21, *buf22, *buf23, *buf24;
  int *bufdate;
  float *buftime;
  short *buflatimg, *buflonimg, *buflatenv, *buflonenv;
  short *buflatlas, *buflonlas, *buflatuas, *buflonuas;
  char *bufsurf;
  char s1[256], sdate[16], stime[16];
  int tdate, start_tdate=-1;
  double ttime, ttime2, start_ttime=-1.0;
  int rev6a;
  unsigned char *str_satid[5] = {"f-16","f-17","f-18","f-19","f-20"};

  /*------------------------------------------------------------*/

  fd= open(inname,0);    /* open a SDR file */
  if (fd == -1) {
    printf("Unable to open input file %s\n", inname);
    exit(1);
  }
  printf("Opened input file %s\n", inname);

  rds(&rev.sw_rev,1);
  read(fd,&rev.endian,2);
  rdf(&rev.rev,2);
  rds(&rev.jday,1);
  read(fd,&rev.hour,2);
  rds(&rev.satid,2);
  read(fd,&rev.spare1,4);
  rds(&rev.spare4,1);
  nbytes+= sizeof(rev_header_record);

  /*------------------------------------------------------------------------------*/
  /*  Rev 6A of the SSMIS SDR software changed the scaling of channel 12-16 to 100 
      Effective with orbit rev 12216 for F-16 and thereafter for all future sats   Added 2006/03/08  JT */
  rev6a= 1;
  if ( rev.satid == 1 && rev.rev < 12216 ) rev6a= 0;
  /*------------------------------------------------------------------------------*/

  printf("Rev=%d year=%d jday=%d hour=%d min=%d\n", rev.rev, rev.year, rev.jday, rev.hour, rev.min);
  printf("satid=%d nsdr=%d nbytes=%d\n", rev.satid, rev.nsdr, nbytes);

  /* Read scan records at 512-byte boundaries */
  nfiller= 512-( nbytes % 512 )+2;
  /*printf("Read %d bytes so far  Filling %d\n", nbytes, nfiller);*/
  read(fd,&filler_bytes[0],nfiller);

  /*----- Initialize LAS data buffers -----*/
  buf01= (short *) malloc(rev.nsdr*8*NSLAS*sizeof(short));
  buf02= (short *) malloc(rev.nsdr*8*NSLAS*sizeof(short));
  buf03= (short *) malloc(rev.nsdr*8*NSLAS*sizeof(short));
  buf04= (short *) malloc(rev.nsdr*8*NSLAS*sizeof(short));
  buf05= (short *) malloc(rev.nsdr*8*NSLAS*sizeof(short));
  buf06= (short *) malloc(rev.nsdr*8*NSLAS*sizeof(short));
  buf07= (short *) malloc(rev.nsdr*8*NSLAS*sizeof(short));
  buflatlas= (short *) malloc(rev.nsdr*8*NSLAS*sizeof(short));
  buflonlas= (short *) malloc(rev.nsdr*8*NSLAS*sizeof(short));

  /*----- Initialize UAS data buffers -----*/
  buf19= (short *) malloc(rev.nsdr*4*NSUAS*sizeof(short));
  buf20= (short *) malloc(rev.nsdr*4*NSUAS*sizeof(short));
  buf21= (short *) malloc(rev.nsdr*4*NSUAS*sizeof(short));
  buf22= (short *) malloc(rev.nsdr*4*NSUAS*sizeof(short));
  buf23= (short *) malloc(rev.nsdr*4*NSUAS*sizeof(short));
  buf24= (short *) malloc(rev.nsdr*4*NSUAS*sizeof(short));
  buflatuas= (short *) malloc(rev.nsdr*4*NSUAS*sizeof(short));
  buflonuas= (short *) malloc(rev.nsdr*4*NSUAS*sizeof(short));

  /*----- Initialize imager data buffers -----*/
  buf08= (short *) malloc(rev.nsdr*28*NSIMG*sizeof(short));
  buf09= (short *) malloc(rev.nsdr*28*NSIMG*sizeof(short));
  buf10= (short *) malloc(rev.nsdr*28*NSIMG*sizeof(short));
  buf11= (short *) malloc(rev.nsdr*28*NSIMG*sizeof(short));
  buf17= (short *) malloc(rev.nsdr*28*NSIMG*sizeof(short));
  buf18= (short *) malloc(rev.nsdr*28*NSIMG*sizeof(short));
  buflatimg= (short *) malloc(rev.nsdr*28*NSIMG*sizeof(short));
  buflonimg= (short *) malloc(rev.nsdr*28*NSIMG*sizeof(short));
  bufsurf= (char *) malloc(rev.nsdr*28*NSIMG*sizeof(char));

  /*----- Initialize environmental data buffers -----*/
  buf12= (short *) malloc(rev.nsdr*28*NSENV*sizeof(short));
  buf13= (short *) malloc(rev.nsdr*28*NSENV*sizeof(short));
  buf14= (short *) malloc(rev.nsdr*28*NSENV*sizeof(short));
  buf15= (short *) malloc(rev.nsdr*28*NSENV*sizeof(short));
  buf16= (short *) malloc(rev.nsdr*28*NSENV*sizeof(short));
  buflatenv= (short *) malloc(rev.nsdr*28*NSENV*sizeof(short));
  buflonenv= (short *) malloc(rev.nsdr*28*NSENV*sizeof(short));

  bufdate = (int *) malloc(rev.nsdr*28*sizeof(int));
  buftime= (float *) malloc(rev.nsdr*28*sizeof(float));

  /*------------------------------------------*/

  for(n= 0; n< rev.nsdr; n++){
    nsdr++;
    nbytes= 0;

    /* Scan record */
    rdf(&scan.syncword,2);
    rds(&scan.jday,1);
    read(fd,&scan.hour,2);
    rdf(&scan.scan,1);
    read(fd,&scan.nscan_imager,4);
    rdf(&scan.start_scantime_imager,28);
    read(fd,&scan.scenecounts_imager,28);
    rdf(&scan.start_scantime_enviro,24);
    read(fd,&scan.scenecounts_enviro,24);
    rdf(&scan.start_scantime_las,8);
    read(fd,&scan.scenecounts_las,8);
    rdf(&scan.start_scantime_uas,4);
    read(fd,&scan.scenecounts_uas,4);
    rdf(&scan.spare,5);
    nbytes+= sizeof(scan_header_record);

    nscan0= scan.scan - 1;  /* make it 0-relative */

    /*
    printf("SCANBUNDLE=%d year=%d jday=%d hour=%d min=%d\n", scan.scan, scan.year, scan.jday, scan.hour, scan.min);
    printf("Nscans=%d %d %d %d\n", scan.nscan_imager, scan.nscan_enviro, scan.nscan_las, scan.nscan_uas);

    for(i=0; i< 28; i++){
      printf("IMAGER i=%2d Starting scantime=%8d Nscenes=%2d\n",i,scan.start_scantime_imager[i],scan.scenecounts_imager[i]);
      if ( i < 24 ) 
        printf("ENVIRO i=%2d Starting scantime=%8d Nscenes=%2d\n",i,scan.start_scantime_enviro[i],scan.scenecounts_enviro[i]);
      if ( i < 8 ) 
        printf("LAS    i=%2d Starting scantime=%8d Nscenes=%2d\n",i,scan.start_scantime_las[i],scan.scenecounts_las[i]);
      if ( i < 4 ) 
        printf("UAS    i=%2d Starting scantime=%8d Nscenes=%2d\n",i,scan.start_scantime_uas[i],scan.scenecounts_uas[i]);
    }
    */
	
    /*----- Imager scene -----*/
    for(i=0; i< scan.nscan_imager; i++){
      /* if ( i > 0 ) printf("IMAGER SCANTIME=%d\n", scan.start_scantime_imager[i]-scan.start_scantime_imager[i-1]); */

      if ( scan.start_scantime_imager[i] >= 0 && scan.start_scantime_imager[i] <= 86400000 ) {
        sprintf(sdate,"%4d.%03d", scan.year, scan.jday);
        ttime= 0.001*scan.start_scantime_imager[i];
        /*printf("IMAGER scan=%d  %s %s  %d %f\n", nscan0+i, sdate, stime, tdate, ttime);*/
        k= (nscan0 + i);
        bufdate[k]= tdate;
        buftime[k]= (float) ttime;
        if ( start_tdate < 0 ) start_tdate= tdate;
        if ( start_ttime < 0 ) start_ttime= ttime;
      }

      for (j=0; j< scan.scenecounts_imager[i]; j++) {
        rds(&imager.latitude,3);
        read(fd,&imager.surf,2);
        rds(&imager.ch08,6);
        nbytes+= sizeof(imager_scene_record);
        lat= 0.01*imager.latitude;
        lon= 0.01*imager.longitude;
        k= NSIMG*(nscan0 + i) + j;
        if ( imager.ch08 >= -19500 && imager.ch08 <= 6000 ) buf08[k]= imager.ch08 + 27315;  /* Kelvin x 100 */
        if ( imager.ch09 >= -19500 && imager.ch09 <= 6000 ) buf09[k]= imager.ch09 + 27315;
        if ( imager.ch10 >= -19500 && imager.ch10 <= 6000 ) buf10[k]= imager.ch10 + 27315;
        if ( imager.ch11 >= -19500 && imager.ch11 <= 6000 ) buf11[k]= imager.ch11 + 27315;
        if ( imager.ch17 >= -19500 && imager.ch17 <= 6000 ) buf17[k]= imager.ch17 + 27315;
        if ( imager.ch18 >= -19500 && imager.ch18 <= 6000 ) buf18[k]= imager.ch18 + 27315;
        if ( imager.latitude >= -9000 && imager.latitude <= 9000 ) buflatimg[k]= imager.latitude;
        if ( imager.longitude >= -18000 && imager.longitude <= 18000 ) buflonimg[k]= imager.longitude;
        if ( imager.surf >= 0 && imager.surf <= 7 ) bufsurf[k]= imager.surf;
        /*hires printout*/
		/*printf("%d %d %d %d %d %d\n",i,j,buflatimg[k],buflonimg[k],buf17[k],buf18[k]);*/
		
      }
    }
	

    /* Enviro scene */
    for (i=0; i< scan.nscan_enviro; i++) {

      ttime2= 0.001*scan.start_scantime_enviro[i];
      /*printf("ENVIRO scan=%d  %s %s  %d %f\n", nscan0+i, sdate, stime, tdate, ttime2);*/

      if ( i % 2 == 0 ) {   /* odd samples for odd scenes */
        for (j=0; j< scan.scenecounts_enviro[i]; j++) {
          rds(&enviro_odd.latitude,3);
          read(fd,&enviro_odd.sea_ice,2);
          rds(&enviro_odd.ch12,11);
          read(fd,&enviro_odd.rain1,2);
          rdf(&enviro_odd.edr_bitflags,1);
          nbytes+= sizeof(enviro_odd_scene_record);
          k= NSENV*(nscan0 + i) + j;
          /*printf("ENVIRO-ODD SCAN=%d SCENE=%d k=%d LatLon=%d %d ch12=%d\n", i,j,k,enviro_odd.latitude,enviro_odd.longitude,enviro_odd.ch12);*/
          if (rev6a == 1 ) {
            if ( enviro_odd.ch12 >= -19500 && enviro_odd.ch12 <= 6000 ) buf12[k]= enviro_odd.ch12 + 27315;
            if ( enviro_odd.ch13 >= -19500 && enviro_odd.ch13 <= 6000 ) buf13[k]= enviro_odd.ch13 + 27315;
            if ( enviro_odd.ch14 >= -19500 && enviro_odd.ch14 <= 6000 ) buf14[k]= enviro_odd.ch14 + 27315;
            if ( enviro_odd.ch15 >= -19500 && enviro_odd.ch15 <= 6000 ) buf15[k]= enviro_odd.ch15 + 27315;
            if ( enviro_odd.ch16 >= -19500 && enviro_odd.ch16 <= 6000 ) buf16[k]= enviro_odd.ch16 + 27315;
          }
          else {
            if ( enviro_odd.ch12 >= -1950 && enviro_odd.ch12 <= 600 ) buf12[k]= 10*enviro_odd.ch12 + 27315;
            if ( enviro_odd.ch13 >= -1950 && enviro_odd.ch13 <= 600 ) buf13[k]= 10*enviro_odd.ch13 + 27315;
            if ( enviro_odd.ch14 >= -1950 && enviro_odd.ch14 <= 600 ) buf14[k]= 10*enviro_odd.ch14 + 27315;
            if ( enviro_odd.ch15 >= -1950 && enviro_odd.ch15 <= 600 ) buf15[k]= 10*enviro_odd.ch15 + 27315;
            if ( enviro_odd.ch16 >= -1950 && enviro_odd.ch16 <= 600 ) buf16[k]= 10*enviro_odd.ch16 + 27315;
          }
          if ( enviro_odd.latitude >= -9000 && enviro_odd.latitude <= 9000 ) buflatenv[k]= enviro_odd.latitude;
          if ( enviro_odd.longitude >= -18000 && enviro_odd.longitude <= 18000 ) buflonenv[k]= enviro_odd.longitude;
          printf("%d %d %d %d %d %d %d %d\n",i,j,buflatenv[k],buflonenv[k],buf12[k],buf13[k],buf15[k],buf16[k]);
        }
      }
      if ( i % 2 == 1 ) {  /* even samples for even scenes */
        for (j=0; j< scan.scenecounts_enviro[i]; j++) {
          rds(&enviro_even.latitude,3);
          read(fd,&enviro_even.sea_ice,2);
          rds(&enviro_even.ch12,5);
          nbytes+= sizeof(enviro_even_scene_record);
          /*printf("ENVIRO-EVEN SCAN=%d SCENE=%d k=%d LatLon=%d %d ch12=%d\n", i,j,k,enviro_even.latitude,enviro_even.longitude,enviro_even.ch12);*/
          k= NSENV*(nscan0 + i) + j;
          if (rev6a == 1 ) {
            if ( enviro_even.ch12 >= -19500 && enviro_even.ch12 <= 6000 ) buf12[k]= enviro_even.ch12 + 27315;
            if ( enviro_even.ch13 >= -19500 && enviro_even.ch13 <= 6000 ) buf13[k]= enviro_even.ch13 + 27315;
            if ( enviro_even.ch14 >= -19500 && enviro_even.ch14 <= 6000 ) buf14[k]= enviro_even.ch14 + 27315;
            if ( enviro_even.ch15 >= -19500 && enviro_even.ch15 <= 6000 ) buf15[k]= enviro_even.ch15 + 27315;
            if ( enviro_even.ch16 >= -19500 && enviro_even.ch16 <= 6000 ) buf16[k]= enviro_even.ch16 + 27315;
          }
          else {
            if ( enviro_even.ch12 >= -1950 && enviro_even.ch12 <= 600 ) buf12[k]= 10*enviro_even.ch12 + 27315;
            if ( enviro_even.ch13 >= -1950 && enviro_even.ch13 <= 600 ) buf13[k]= 10*enviro_even.ch13 + 27315;
            if ( enviro_even.ch14 >= -1950 && enviro_even.ch14 <= 600 ) buf14[k]= 10*enviro_even.ch14 + 27315;
            if ( enviro_even.ch15 >= -1950 && enviro_even.ch15 <= 600 ) buf15[k]= 10*enviro_even.ch15 + 27315;
            if ( enviro_even.ch16 >= -1950 && enviro_even.ch16 <= 600 ) buf16[k]= 10*enviro_even.ch16 + 27315;
          }
          if ( enviro_even.latitude >= -9000 && enviro_even.latitude <= 9000 ) buflatenv[k]= enviro_even.latitude;
          if ( enviro_even.longitude >= -18000 && enviro_even.longitude <= 18000 ) buflonenv[k]= enviro_even.longitude;
          printf("%d %d %d %d %d %d %d %d\n",i,j,buflatenv[k],buflonenv[k],buf12[k],buf13[k],buf15[k],buf16[k]);
        }
      }
    }

    /* LAS scene */
    for(i=0; i< scan.nscan_las; i++){
      for(j=0; j< scan.scenecounts_las[i]; j++){
        rds(&las.latitude,17);
        read(fd,&las.las_tqflag,2);
        rds(&las.terrain,2);
        nbytes+= sizeof(las_scene_record);
        k= NSLAS*nscan_las + j;
/*        printf("LAS SCAN=%d SCENE=%d k=%d LatLon=%d %d ch01=%d\n", i,j,k,las.latitude,las.longitude,las.ch01_3x3);*/
        if ( las.ch01_3x3 >= -19500 && las.ch01_3x3 <= 6000 ) buf01[k]= las.ch01_3x3 + 27315;
        if ( las.ch02_3x3 >= -19500 && las.ch02_3x3 <= 6000 ) buf02[k]= las.ch02_3x3 + 27315;
        if ( las.ch03_3x3 >= -19500 && las.ch03_3x3 <= 6000 ) buf03[k]= las.ch03_3x3;
        if ( las.ch04_3x3 >= -19500 && las.ch04_3x3 <= 6000 ) buf04[k]= las.ch04_3x3;
        if ( las.ch05_3x3 >= -19500 && las.ch05_3x3 <= 6000 ) buf05[k]= las.ch05_3x3;
        if ( las.ch06_3x3 >= -19500 && las.ch06_3x3 <= 6000 ) buf06[k]= las.ch06_3x3 + 27315;
        if ( las.ch07_3x3 >= -19500 && las.ch07_3x3 <= 6000 ) buf07[k]= las.ch07_3x3 + 27315;
        if ( las.latitude >= -9000 && las.latitude <= 9000 ) buflatlas[k]= las.latitude;
        if ( las.longitude >= -18000 && las.longitude <= 18000 ) buflonlas[k]= las.longitude;

/* pass lat/lon bounds and channel of interest from script */


 
/*            printf ("LAS SCAN= %d SCENE= %d k= %d LatLon= %d %d CHANNEL= %d\n", i,j,k,buflatlas[k],buflonlas[k],CHANNEL[k]); */
       
      }
      nscan_las++;
    }

    /* UAS scene */
    for(i=0; i< scan.nscan_uas; i++){
      for(j=0; j< scan.scenecounts_uas[i]; j++){
        rds(&uas.latitude,10);
        rdf(&uas.field,2);
        nbytes+= sizeof(uas_scene_record);
        k= NSUAS*nscan_uas + j;
        /*printf("UAS SCAN=%d SCENE=%d k=%d LatLon=%d %d ch19=%d\n", i,j,k,uas.latitude,uas.longitude,uas.ch19_6x6);*/
        if ( uas.ch19_6x6 >= -19500 && uas.ch19_6x6 <= 6000 ) buf19[k]= uas.ch19_6x6 + 27315;
        if ( uas.ch20_6x6 >= -19500 && uas.ch20_6x6 <= 6000 ) buf20[k]= uas.ch20_6x6 + 27315;
        if ( uas.ch21_6x6 >= -19500 && uas.ch21_6x6 <= 6000 ) buf21[k]= uas.ch21_6x6 + 27315;
        if ( uas.ch22_6x6 >= -19500 && uas.ch22_6x6 <= 6000 ) buf22[k]= uas.ch22_6x6 + 27315;
        if ( uas.ch23_6x6 >= -19500 && uas.ch23_6x6 <= 6000 ) buf23[k]= uas.ch23_6x6 + 27315;
        if ( uas.ch24_6x6 >= -19500 && uas.ch24_6x6 <= 6000 ) buf24[k]= uas.ch24_6x6 + 27315;
        if ( uas.latitude >= -9000 && uas.latitude <= 9000 ) buflatuas[k]= uas.latitude;
        if ( uas.longitude >= -18000 && uas.longitude <= 18000 ) buflonuas[k]= uas.longitude;
      }
      nscan_uas++;
    }

    /* Read at 512-byte boundaries */
    nfiller= 512 - ( nbytes % 512 );
    /*printf("Read %d bytes so far  Filling %d\n", nbytes, nfiller);*/
    read(fd,&filler_bytes[0],nfiller);

    /*printf("----- END OF SCAN %d ------\n", n);*/

  }

  close(fd);

  printf("Number of scan bundles read=%d\n", nsdr);

  /* Check for timegaps to identify missing lines */
  for(n= 0; n< 24*rev.nsdr; n++){
    sec= 86400.0*bufdate[n] + buftime[n];
    nlines= ((sec - sec_prev)/SEC_REV) + 0.5;
    if ( n > 0 ) {
      /*printf("Scan=%d Time=%f Delta=%f Lines=%d\n", n, sec, sec-sec_prev, nlines);*/
      /*if ( nlines != 1 ) return(0);*/
    }
    sec_prev= sec;
  }

  return(0);
} 

int swapbytes(fptr, n) 
char *fptr;
int n;
{
  int i, i1;
  char temp[n];
  for(i=0; i< n; i++){
    i1= (n-1)-i;
    temp[i]= fptr[i1];
  }
  for(i=0; i< n; i++){
    fptr[i]= temp[i1];
  }
  return(0);
}

int rds(dptr, n)   /* short integer */
char *dptr;
int n;{
  int i=0;
  if(sm)
    for(;n>0;n--,dptr+=2){
     i+=read(fd,dptr+1,1);
     i+=read(fd,dptr,1);
    }
  else
    i=read(fd,dptr,n<<1);
  return(i);
}
int rdf(dptr, n)   /* float */
char *dptr;
int n;{
  int i=0;
  if(sm)
    for(;n>0;n--,dptr+=4){
     i+=read(fd,dptr+3,1);
     i+=read(fd,dptr+2,1);
     i+=read(fd,dptr+1,1);
     i+=read(fd,dptr,1);
    }
  else
    i=read(fd,dptr,n<<2);
  return(i);
}
int rdd(dptr, n)   /* double */
char *dptr;
int n;{
  int i=0;
  if(sm)
    for(;n>0;n--,dptr+=8){
     i+=read(fd,dptr+7,1);
     i+=read(fd,dptr+6,1);
     i+=read(fd,dptr+5,1);
     i+=read(fd,dptr+4,1);
     i+=read(fd,dptr+3,1);
     i+=read(fd,dptr+2,1);
     i+=read(fd,dptr+1,1);
     i+=read(fd,dptr,1);
    }
  else
    i=read(fd,dptr,n<<3);
  return(i);
}
