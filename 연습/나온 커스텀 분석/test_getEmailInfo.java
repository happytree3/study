package kr.co.proten.custom.data;

import java.io.File;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import kr.co.proten.common.util.FileUtil;
import kr.co.proten.common.util.HtmlUtil;
import kr.co.proten.common.util.StringUtil;
import kr.co.proten.config.GetConfig;
import kr.co.proten.common.util.PropsReader;
import kr.co.proten.custom.ClassName;
import kr.co.proten.custom.data.email.EmailInfo;
import kr.co.proten.custom.data.email.EmailParser;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
/**
 * 
 * @author ALEX
 * 
 * [] 
 *  - kr/co/proten/custom/data/email/EmailInfo 
 *  - kr/co/proten/custom/data/email/EmailParser 
 *  - kr/co/proten/common/util/html/*
 *  - kr/co/proten/common/util/HtmlUtil
 *  - kr/co/proten/common/util/PropsReader
 *  - kr/co/proten/db/DBService   : 
 * []
 *  - activation-1.1.1.jar 
 *  - javax.mail-1.6.2.jar
 */
public  class getEmailInfo implements ClassName{
	StringBuffer email = new StringBuffer();
	private static final Logger log = LoggerFactory.getLogger(getEmailInfo.class);
	
	public Object  customDataObject(String str) {
		LinkedHashMap<String,Object> resultList = new LinkedHashMap<>();
		List<LinkedHashMap<String,Object>> tmpFileList = new ArrayList<LinkedHashMap<String, Object>>();
	
//  /mnt/kdgfs/gwstore/mailServer/var/store/maildir/|22665179731701819500|built1|nipark@kdgas.co.kr|7|1703652989.MG.208762a9896759@kdprdgrp01129275.kdprdgrp01,S=210272:2,S
	
    	email.setLength(0);
    	String infos[]=StringUtil.split(str, "|");
		
		// | 로 스플릿 해서 나눈다
    	EmailInfo mailinfo = new EmailInfo();
    	if(infos.length > 5){
			//위와 같은 형식이면 6이라 이 로직을 탄다.
    		String domain="";
        	String id="";
        	String uid="";
        	String path="";
        	String boxId="";
        	String boxNm="";
        	String fileName = "";
        	try {
	    		uid = infos[4];
				// uid = 7
	    		path = infos[0];
				// path = /mnt/kdgfs/gwstore/mailServer/var/store/maildir/
	    		boxId  = infos[1];
				// boxId = 22665179731701819500
	    		boxNm = infos[2];
	    		// boxNm = built1
	    		fileName = infos[5];
				// fildName = 1703652989.MG.208762a9896759@kdprdgrp01129275.kdprdgrp01,S=210272:2,S
	    		String eInfos[]=StringUtil.split(infos[3], "@");
				// infos[3] = nipark@kdgas.co.kr 이고 @로 또 스플릿.
				
	    		if(eInfos.length> 0) {
					// @ 가 포함되어있으면 무조건 이 로직 탄다.
	    			id = eInfos[0];
					// id = nipark
	    			domain= eInfos[1];
					// domain = kdgas.co.kr
	    		}else {
	    			log.debug("eInfos  ===  " + infos[3]);
					// 아니면 @ 가 아니라고 로그 찍는다.
	    		}
	    		
	    		String mailPath = "";
	    		String addPath = "";
	    		// 변수 선언.
	    		if(!"inbox".equals(boxNm.toLowerCase())){
	    			// boxNm을 소문자로 바꾼다음에 만약에 inbox가 아니면 addPath 에 built1 를 추가한다.
	    			addPath = FileUtil.fileseperator+"."+boxNm;
	    		}
                
    			File mailFile = null;
    			try{
    				
    				 mailPath = path + domain + FileUtil.fileseperator + id + addPath + FileUtil.fileseperator + "new" + FileUtil.fileseperator + StringUtil.replace(fileName, ":", "_");
					 // mailPath = /mnt/kdgfs/gwstore/mailServer/var/store/maildir/kdgas.co.kr/nipark/built1/new/1703652989.MG.208762a9896759@kdprdgrp01129275.kdprdgrp01,S=210272_2,S
					 ///mnt/kdgfs/gwstore/mailServer/var/store/maildir/kdgas.co.kr/nipark/.built1/cur 근데 실제로는 built1은 . 으로 숨긴디렉토리 이다.
					 // 여기선 addPath 가 built1 이다.
                     mailFile = new File(mailPath.trim());
                     if (!mailFile.exists())
						 // new 디렉토리에 아무것도 없어서 mailFile이 존재 하지 않을 경우 이 루트를 탄다. ( 대부분 여기를 탐 )
                     {
                       mailPath = path + domain + FileUtil.fileseperator + id + addPath + FileUtil.fileseperator + "cur" + FileUtil.fileseperator + StringUtil.replace(fileName, ":", "_");
			// mailPath = /mnt/kdgfs/gwstore/mailServer/var/store/maildir/kdgas.co.kr/nipark/.built1/cur/1703652989.MG.208762a9896759@kdprdgrp01129275.kdprdgrp01,S=210272_2,S
                       mailFile = new File(mailPath.trim());

                       if (!mailFile.exists())
                       {
                         mailPath = path + domain + FileUtil.fileseperator + id + addPath + FileUtil.fileseperator + "new" + FileUtil.fileseperator + fileName;
						// mailPath = /mnt/kdgfs/gwstore/mailServer/var/store/maildir/kdgas.co.kr/nipark/built1/new/1703652989.MG.208762a9896759@kdprdgrp01129275.kdprdgrp01,S=210272:2,S
						// 이번엔 : 를 _ 로 안 바꾸고 확인.
                         mailFile = new File(mailPath.trim());
                         if (!mailFile.exists())
                         {
                           mailPath = path + domain + FileUtil.fileseperator + id + addPath + FileUtil.fileseperator + "cur" + FileUtil.fileseperator + fileName;
						// 여기도 안바꾸고 확인
                           mailFile = new File(mailPath.trim());
                         }
                       }
                     }
                     log.debug("==mailPath ==============="+mailPath);
                     log.debug("==mailFile ==============="+mailFile);
                     
    			}catch(Exception ex){
    				log.error("getEmailInfo Exception  : " + ex);
					// 파일이 없으면 에러로그 발생.
    			}
    			if(mailFile!=null){
					// mailFile이 있다는건 파일이 존재한다는 의미.
    				List<LinkedHashMap<String, Object>> fileList = new ArrayList<LinkedHashMap<String, Object>>();
    				mailinfo=EmailParser.display(mailFile);
					// 찾은 mailFile을 EmailParser.java에서 사용

					resultList.put("doc_subject", mailinfo.getSubject());
			        resultList.put("doc_content", HtmlUtil.getHtmlParse(mailinfo.getBody().getBytes("UTF-8")));
			        resultList.put("doc_send_user", mailinfo.getFrom());
			        resultList.put("doc_recv_users", mailinfo.getTo());
					
					//첨부파일의 경우 nested형태로 받게 수정
			  	    String[] filenm = StringUtil.split(mailinfo.getFile(), "%@%");
			  	    String[] filecont = StringUtil.split(mailinfo.getFileContent(), "%@%");
			  	    for (int f=0; f < filenm.length; f++) {
					  if (!"".equals(filenm[f])) {	
						LinkedHashMap<String, Object> fileMap = new LinkedHashMap<>();
						fileMap.put("file_real_name", filenm[f]);
						if (filecont.length > 0){
							fileMap.put("file_content", filecont[f]);
						} else {
							fileMap.put("file_content", "");
						}
						
						fileList.add(fileMap);
					  }
			  	    }
			  	    resultList.put("doc_files", fileList);
					
					
    			}
			        
			} catch (Exception e) {
				e.printStackTrace();
				log.error("getEmailInfo e : " + e);
			}
    		
    	}else{
    		
    	}
    	
    	return resultList;
    	
    	
    }

//	@Override
//	public Object customDataObject(String data) throws Exception {
//		// TODO Auto-generated method stub
//		return null;
//	}
	private static String methodThatTakesLongTime(int timeout) throws InterruptedException {
		Thread.sleep(timeout);
		return "wow it takes too long";
	}
	@Override
	public String customDataMemory(String data, Map<String, String[]> resultMemory) throws Exception {
		// TODO Auto-generated method stub
		return null;
	}


	@Override
	public List<String> customDataAfter(String data) throws Exception {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public String customData(String data) throws Exception {
		// TODO Auto-generated method stub
		return null;
	}
	 
     
}
