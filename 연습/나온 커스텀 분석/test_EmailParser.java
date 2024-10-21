package kr.co.proten.custom.data.email;

import com.sun.mail.util.BASE64DecoderStream;

import kr.co.proten.common.util.FileUtil;
import kr.co.proten.common.util.StringUtil;
import kr.co.proten.custom.data.getEmailInfo;
import kr.co.proten.filter.FileContent;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.PrintStream;
import java.text.SimpleDateFormat;
import java.util.Enumeration;
import java.util.Properties;
import javax.mail.Address;
import javax.mail.Multipart;
import javax.mail.Part;
import javax.mail.Session;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;
import javax.mail.internet.MimeUtility;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class EmailParser {
	private static FileContent fileContent =  new FileContent(true);
//	static EmailInfo mail = new EmailInfo();	22.11.17 38 라인으로 이동
	private static final Logger log = LoggerFactory.getLogger(EmailParser.class);
	
	public EmailParser(){
		
	}
	public static EmailInfo display(File emlFile) throws Exception{
		
		// /mnt/kdgfs/gwstore/mailServer/var/store/maildir/kdgas.co.kr/nipark/.built1/cur/1703652989.MG.208762a9896759@kdprdgrp01129275.kdprdgrp01,S=210272_2,S
		// 형태를 받는다고 가정하면
		EmailInfo mail = new EmailInfo();
		// mail 객체 선언.
        Properties props = System.getProperties();
        SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmmss");
        Session mailSession = Session.getDefaultInstance(props, null);
        String filename = emlFile.getAbsolutePath();

        try{
        	String temp = "";
        	int cnt =-1;
			log.debug("emlFile.isFile() :"+emlFile.isFile());
        	if(emlFile.isFile()){
		        InputStream source = new FileInputStream(emlFile);
		        MimeMessage message = new MimeMessage(mailSession, source);
//		        System.out.println("message.getSubject() :: " + message.getSubject()); 
		        if(message.getSubject() != null ) {
		        	mail.setSubject( message.getSubject());
		        	try{
		        		Address[] fromAddresses = message.getFrom();
						if (fromAddresses != null) {
							cnt =  message.getFrom().length;
							for(int idx = 0;  idx < cnt;idx++){
								if (fromAddresses[idx] != null) {
									temp +=decodeString(message.getFrom()[idx].toString(),"");
									if(idx != cnt-1) {
										temp +="|";
									}
								}
							}
						}
		        	}catch(Exception ex){
		        		log.error(" EmailParser from ex : " + ex);
		        		
		        		ex.printStackTrace();
		        		String headers[]=message.getHeader("From");
						if (headers != null) {
							cnt = headers.length;
							log.debug("cnt"+cnt);
							for(int idx = 0;  idx < cnt; idx++){
								temp +=decodeString(replaceString(headers[idx]),filename);
								log.error("from  Cc  : " + (headers[idx]));
							}
						}
		        	}finally {
		        		mail.setFrom(temp);//보낸사람
		        	}
		        
		        temp = "";
		        try{
					if (message.getAllRecipients() != null) {
						cnt =  message.getAllRecipients().length;
						Address recipient = null;
						log.debug(emlFile.getAbsolutePath()); 
						for(int idx = 0;  idx < cnt;idx++){
							recipient = message.getAllRecipients()[idx];
							if (recipient != null) {
								temp +=decodeString(message.getAllRecipients()[idx].toString(),filename);
								if(idx != cnt-1) {
									temp +="|";
								}
							}							
						}
					}
		        }catch(Exception ex){
		        	log.error(" EmailParser message ex  : " + ex);
		     	log.debug(emlFile.getAbsolutePath());   
		        	String headers[]=message.getHeader("To");
			        cnt = headers.length;
			        //System.out.println("cnt"+cnt);
			        for(int idx = 0;  idx < cnt;idx++){
			        	temp +=decodeString(replaceString(headers[idx]),filename);
		       	log.debug("Cc:"+(headers[idx]));
			        	log.error("message  Cc  : " + (headers[idx]));
			        }
			        
		        }finally {
		        	mail.setTo(temp);//받는사람
		        }
		        
	       log.debug("--------------"+message.getSentDate());
		        if (message.getSentDate()==null )
		        	mail.setDate("");
		        else
		        	mail.setDate(sdf.format(message.getSentDate()));
		        //
	   //     System.out.println("Body : " +  ((MimeMultipart)message.getContent()).getBodyPart(0). );
		        
		        Object objContent = message.getContent();
		        MimeMultipart mm = null;
		        StringBuffer body = new StringBuffer();
		        StringBuffer file = new StringBuffer();
		        StringBuffer attachContent = new StringBuffer();
		        if ( objContent instanceof Multipart ) { 
		            mm = (MimeMultipart) objContent;
		           int bodyCount = mm.getCount();
		            String bodycont[]=null;
					log.debug("bodyCount: "+bodyCount);
					//System.out.println("bodyCount: "+bodyCount);
			  
		            for (int i = 0; i < bodyCount; i++) {
		            	bodycont=processPart(mm.getBodyPart(i));
						//System.out.println("bodycont[0].indexOf(: "+bodycont[0].indexOf("<"));
		            	body.append(bodycont[0]).append("|");
		            	
		            	if(i < bodyCount -1 &&  !bodycont[1].trim().equals("") ) {
		            		file.append(bodycont[1].trim()).append("%@%");
							attachContent.append(bodycont[2].trim()).append("%@%");
		            	}else {
		            		file.append(bodycont[1].trim());
							attachContent.append(bodycont[2].trim());
		            	} 
						/*
		            	if(i < bodyCount -1 &&  !bodycont[2].equals("") ) {
		            		attachContent.append(bodycont[2]).append("%@%");
		            	}else {
		            		attachContent.append(bodycont[2]);
		            	} 
						*/
		            }
		        }
		        else {
					//System.out.println("bodyCount: "+objContent.toString());
		        	body.append(objContent.toString()).append("|");
		        }
		        mail.setBody(body.toString());
	       log.debug("file.toString() : "+ file.toString());
		        mail.setFile(file.toString());
		        //첨부파일 추가 
				mail.setFileContent(attachContent.toString());
	        	}     
		    }
        }catch(Exception ex){
        	ex.printStackTrace();
        	log.error("EmailInfo   ex  : " + ex);
      	log.debug(emlFile.getAbsolutePath());
        }finally {
        	return mail;
        }

    }

	
	
	//---------------------------------
	// process part
	//---------------------------------
	public static String[] processPart(Part part) throws Exception {
		String[] retValue = new String[]{"","",""};
		String contentType = part.getContentType();
		String fileName = part.getFileName();
		String disposition = part.getDisposition();
		boolean isAttachement = false;
		String attachContent =  "";
		
		StringBuffer filenm = new StringBuffer();
		StringBuffer content = new StringBuffer();
//		System.out.println("Part.ATTACHMENT //"+Part.ATTACHMENT);
//		System.out.println("part.getDisposition() /"+part.getDisposition());
//		System.out.println(fileName+"//"+disposition);
		//System.out.println("contentType "+contentType);
	try {
		if (fileName != null || disposition != null) {
			isAttachement = true;
		}
		if (part.isMimeType("text/*")) {
			//System.out.println("TEXT----"+part.getContent().toString());
			if(isAttachement) {
				if(fileName!=null)
					filenm.append(decodeString(fileName.toString(),"") + " ");
			}
			else {
				if(contentType.indexOf("html") > 0) {
					//System.out.println("TEXT----"+part.getContent().toString());
					content.append((part.getContent().toString())+" ");
				}
			}
							
		} else if (part.isMimeType("multipart/*")) {
			//System.out.println("multipart----"+part.getContent().toString());
		    Multipart mp = (Multipart)part.getContent();	 
		    
//		    System.out.println("multipart----"+mp.getCount());
		    
		    for (int i = 0; i < mp.getCount(); i++) {
		    	retValue = processPart(mp.getBodyPart(i));
		    	content.append(retValue[0]);
		    	filenm.append(retValue[1]);
				
		    }
		   
			
		} else if (part.isMimeType("message/rfc822")) {
			//System.out.println("message----"+part.getContent().toString());
			retValue = processPart((Part)part.getContent());
			content.append(retValue[0]);
	    	filenm.append(retValue[1]);
		} else if (part.isMimeType("message/rfc822")) {
			
		} else if (Part.ATTACHMENT.equalsIgnoreCase(part.getDisposition())) {
			//System.out.println("99message----"+part.getContent().toString());
			
			String file=decodeString(fileName.toString(),"");
			filenm.append(file   + " ");	
			//첨부파일 다운 로드 및 필터링
			String proten_home = "";
			log.debug("System.getProperty(\"crawler_path\") :: " + System.getProperty("crawler_path"));
			
	        if(System.getProperty("crawler_path") != null){
	        	proten_home = System.getProperty("crawler_path");
	        } else {
	        	proten_home="C:\\search\\prosearch\\dbcrawler\\filter";
	        }
	        log.debug("proten_home :: " + proten_home);
	        
			String destFilePath =  proten_home + FileUtil.fileseperator +  "filter" + FileUtil.fileseperator+ file;
//			System.out.println("destFilePath :" + destFilePath);
			// 필터링 후 첨부파일 삭제
		try {
			FileOutputStream output = new FileOutputStream(destFilePath);
			
			InputStream input = part.getInputStream();
			 
			byte[] buffer = new byte[64*1024];
			 
			int byteRead;
			 
			while ((byteRead = input.read(buffer)) != -1) {
			    output.write(buffer, 0, byteRead);
			}
			output.close();
			
			File srcFile = new File(destFilePath);
			
			if(srcFile.exists()) {
				// 첨부파일 추가 20210329
				attachContent += fileContent.getFilterData(destFilePath);
				
				srcFile.delete();
				
			}else {
				log.info("File Not Find :"+srcFile.getAbsolutePath());
			}
		 }catch(Exception ex){
		     	ex.printStackTrace();
		     	log.error("attachFile   Exception  : " + ex);
	     }finally {
	    	
	     }
		} else {
			if(isAttachement) {
            	if(fileName!=null)
        		filenm.append(decodeString(fileName.toString(),"") + " ");	
        		//System.out.println("1///"+part.getContent().toString());
        	}
        	else {
        		//System.out.println("2///"+part.getContent().toString());
        		content.append((part.getContent().toString())+" ");
        	}
			
		}
//		System.out.println("content.toString()"+content.toString());
		retValue[0]=content.toString();
		retValue[1]=filenm.toString();
		retValue[2]=attachContent;
		return retValue;
	 }catch(Exception ex){
     	ex.printStackTrace();
     	log.error("processPart   ex  : " + ex);
//     	System.out.println(emlFile.getAbsolutePath());
     }finally {
    	 return retValue;
     }

//		return retValue;
	}
	
	public static String decodeString( String str,String filename) throws Exception {

  		if(str == null || str.trim().length() == 0) { return str; }
  	
  		//2023.03.16 quoted-printable 디코딩
  		if(str.startsWith("=?") && str.indexOf("?Q?")>-1) {
                        return MimeUtility.decodeText(str);
                }

		if(str.startsWith("=?") && str.endsWith("?=") && str.indexOf("=?",3)==-1) {
  			return MimeUtility.decodeWord(str);
  		}
  		
  		String result = "";
  		
  		String begin = "=?";
  		String end = "?=";

  		char[] strarr = str.toCharArray();
  		char[] barr = begin.toCharArray();
  		char[] earr = end.toCharArray();
  		
  		int cidx = 0;
  		int fidx = 0;
  		int tidx = 0;
  		
  		while(cidx < strarr.length) {
  			
  			fidx =  searchPattern(strarr, barr, cidx);
  			
  			if(fidx >= 0) {
  				
  				if(fidx > cidx) { 
  					result += toHangle(new String(strarr, cidx, fidx - cidx)).trim();
  				}
  				
  				tidx = searchPattern(strarr, earr, fidx);
  				if(tidx >= 0) {
  					try{
  						result += MimeUtility.decodeWord(new String(strarr, fidx, tidx - fidx + earr.length)).trim();
  						//System.out.println("1/"+MimeUtility.decodeWord(new String(strarr, fidx, tidx - fidx + earr.length)).trim());
  						
  						//System.out.println("1/"+new String(strarr, fidx, tidx - fidx + earr.length));
  					}catch(Exception ex){
  						//System.out.println(filename);
  					}
  					cidx = tidx + earr.length;
  				}
  				else {
  					//System.out.println("2/"+toHangle(new String(strarr, fidx, strarr.length - fidx)).trim());
  					//System.out.println("2/"+MimeUtility.decodeWord(new String(strarr, fidx, strarr.length - fidx)).trim());
	  				result += toHangle(new String(strarr, fidx, strarr.length - fidx)).trim();
	  				break;
  				}
  			}
  			else {
  				//System.out.println("3/"+MimeUtility.decodeWord("=?"+new String(strarr, cidx, strarr.length - cidx)).trim());
  				//System.out.println("3/"+(new String(strarr, cidx, strarr.length - cidx).trim()));
  				result += toHangle(new String(strarr, cidx, strarr.length - cidx)).trim();
  				break;
  			}
  			
  		}
  		
  		return result;
  	
  }
	
	
	
	//------------------------------------
	  // to hangle
	  //------------------------------------
	  public static String toHangle(String in) throws Exception {
	  		return new String(in.getBytes("8859_1"), "ksc5601");
	  }    
	  
	  public static String replaceString(String in) throws Exception {
	  		in = StringUtil.replace(in, "&gt;", ">");
	  		in = StringUtil.replace(in, "&lt;", "<");
	  		return in;
	  }    
	
	public static int searchPattern(char[] src, char[] pattern, int begin) {

  		if(src == null || src.length == 0 || pattern == null || pattern.length == 0 || begin < 0) { return -2; }
  		
		for(int i=begin; i < src.length; i++) {
			if(src[i] == pattern[0]) {
				for(int j=0; j < pattern.length; j++) {
					if(src.length <= (i+j)) { return -3; }
					if(src[i+j] != pattern[j]) { break; }
					if(j == (pattern.length -1)) { return i; }
				}
			}
		}
			
  		return -1;
  		
  }
	
	public static void  main(String args[]){
		try {
			EmailInfo info=EmailParser.display(new File("C:\\naon\\1402909289.9a95669289675219177.gw6,S=10165_2,S"));
			//System.out.println(info.body);
			System.out.println(info.from);
			System.out.println(info.to);
			System.out.println(info.subject);
			System.out.println(info.file);
			
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}


}
