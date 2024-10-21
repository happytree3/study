<% request.setCharacterEncoding("UTF-8");%><%@ page import="org.elasticsearch.search.builder.SearchSourceBuilder
,org.elasticsearch.client.RestClient
,org.elasticsearch.client.RestClientBuilder
,org.elasticsearch.client.RestHighLevelClient
,org.apache.http.HttpHost
,org.apache.lucene.search.join.ScoreMode
,org.elasticsearch.action.search.*
,org.elasticsearch.common.unit.TimeValue
,org.elasticsearch.client.RequestOptions
,org.elasticsearch.common.xcontent.XContentBuilder
,org.elasticsearch.index.query.*
,org.elasticsearch.search.fetch.subphase.highlight.HighlightBuilder
,org.elasticsearch.search.aggregations.*
,org.elasticsearch.search.aggregations.bucket.terms.TermsAggregationBuilder
,org.elasticsearch.search.sort.FieldSortBuilder
,org.elasticsearch.search.sort.ScoreSortBuilder
,org.elasticsearch.search.sort.SortOrder
,org.elasticsearch.search.*
,org.elasticsearch.search.fetch.subphase.highlight.*
,org.elasticsearch.search.fetch.subphase.highlight.HighlightBuilder.Order
,org.elasticsearch.search.fetch.subphase.FetchSourceContext
,org.elasticsearch.common.text.*
,org.apache.commons.logging.* 
,com.google.gson.* 
,java.net.*,java.io.*
,org.elasticsearch.search.aggregations.bucket.terms.Terms.Bucket
,org.elasticsearch.search.aggregations.bucket.terms.Terms
,org.elasticsearch.search.sort.GeoDistanceSortBuilder 
,org.elasticsearch.search.sort.ScoreSortBuilder
,org.elasticsearch.common.unit.DistanceUnit
,org.elasticsearch.common.geo.GeoDistance
,java.util.*,java.io.IOException,java.net.*"%><%@ include file="./ProSearchProperties.jsp"%><%@ include file="./ProUtils.jsp"%><%@ include file="./ProPaging.jsp"%><%!
 
public class ProSearch {

    private StringBuffer debugMsgBuffer = null;
    private StringBuffer errorMsgBuffer = null;
    private StringBuffer warnMsgBuffer = null;

    private boolean isDebug = false;
    private String query = "";

    private MultiSearchRequest multiSearchRequest = null;
    private MultiSearchResponse multiSearchResponse = null;

    public RestHighLevelClient client = null;
    public Map<String,Integer> multiSearchIndex = null;
    public Map<String,Object> searchMap  = null;

    public List<String> indexList  = null;
    
    /**
     * ProSearch 생성자를 생성한다.
     * @param isDebug :: Debug 모드로 값을 화면에서 확인할 경우 사용한다. Default : False
     */
    public ProSearch(boolean isDebug, String [] esIndex) {
		
        this.isDebug = isDebug;
        this.debugMsgBuffer 	= new StringBuffer();
        this.errorMsgBuffer 	= new StringBuffer();
        this.warnMsgBuffer 		= new StringBuffer();
        this.multiSearchRequest = new MultiSearchRequest();
        this.multiSearchIndex 	= new HashMap();
        this.searchMap 			= new HashMap();
        this.indexList 			= new LinkedList<>();
		
        for ( int idx=0; idx < esIndex.length; idx++) {
            int  xdx = getIndexIdx(esIndex[idx]);
            if ( xdx != -1 ) {
                this.addIndex( esIndex[idx] );
                if ( !"".equals(SEARCH_INDEX_SETS[xdx][DEFAULT_ALIAS_NAME].trim()) )
                    this.setAlias( esIndex[idx],			SEARCH_INDEX_SETS[xdx][DEFAULT_ALIAS_NAME] );
                if ( !"".equals(SEARCH_INDEX_SETS[xdx][DEFAULT_SORT_FIELD].trim()) )
                    this.setSortField( esIndex[idx],		SEARCH_INDEX_SETS[xdx][DEFAULT_SORT_FIELD] );
                if ( !"".equals(SEARCH_INDEX_SETS[xdx][DEFAULT_SEARCH_FIELD].trim()) )
                    this.setSearchField( esIndex[idx],		SEARCH_INDEX_SETS[xdx][DEFAULT_SEARCH_FIELD] );
                if ( !"".equals(SEARCH_INDEX_SETS[xdx][DEFAULT_EXCLUDE_FIELD].trim()) )
                    this.setExcludeField( esIndex[idx],		SEARCH_INDEX_SETS[xdx][DEFAULT_EXCLUDE_FIELD] );
                if ( !"".equals(SEARCH_INDEX_SETS[xdx][DEFAULT_INCLUDE_FIELD].trim()) )
                     this.setIncludeField( esIndex[idx],	SEARCH_INDEX_SETS[xdx][DEFAULT_INCLUDE_FIELD] );
                if ( !"".equals(SEARCH_INDEX_SETS[xdx][DEFAULT_HIGHLIGHT_FIELD].trim()) )
                    this.setHighlightField( esIndex[idx],	SEARCH_INDEX_SETS[xdx][DEFAULT_HIGHLIGHT_FIELD] );
                if ( !"".equals(SEARCH_INDEX_SETS[xdx][DEFAULT_FILTER_QUERY].trim()) )
                    this.setFilterQuery( esIndex[idx],		SEARCH_INDEX_SETS[xdx][DEFAULT_FILTER_QUERY] );
                if ( !"".equals(SEARCH_INDEX_SETS[xdx][DEFAULT_INDEX_VIEW_NAME].trim()) )
                     this.setIndexViewName( esIndex[idx],	SEARCH_INDEX_SETS[xdx][DEFAULT_INDEX_VIEW_NAME] );

            }
        }
		
    }
	
    /**
     * 검색엔진서버에 접속한다
     * @return
     */

    public synchronized boolean connection() {

        String [] servers  =  ProUtils.split(ES_SERVERS,SPECIAL_CHAR_COMMA);

        boolean isConnection = false;
        List<HttpHost> hostList = new ArrayList<>();
        for(String server : servers) {
            String host = ProUtils.split(server,":")[0];
            String sport = ProUtils.split(server,":")[1];
            int port = ProUtils.parseInt(sport,6201);
            hostList.add(new HttpHost(host, port, "http"));
        }

        RestClientBuilder builder = RestClient.builder(hostList.toArray(new HttpHost[hostList.size()]));
        client = new RestHighLevelClient(builder);

        if( client != null ) {
            isConnection =  true;
        }
        appendDebug("ElasticSearch Connection URL : " + ES_SERVERS );
        appendDebug("ElasticSearch Connection Success : " + isConnection );
        return isConnection;
    }

    /**
     * 검색엔진서버에 접속을 종료한다.
     * @return
     */
    public synchronized void close() {
        try {
            if ( client != null ) {
                client.close();
                client = null;
            }
        } catch ( IOException e ) {
            appendERROR(e.getMessage());
        }
    }

    public int getIndexIdx(String idxName) {

        for(int idx = 0 ; idx < SEARCH_INDEX_SETS.length ; idx++){
			
            if(SEARCH_INDEX_SETS[idx][DEFAULT_INDEX_NAME].equals(idxName)) {
                return idx;
            }
        }
        return -1;
    }
	 

    /**
     * 설정된 값으로 조건을 조합하여   msearch 에 검색을 요청한다.
     * @param query     ::: 검색어
     * @param esIndex   ::: index List
     * @return
     */

    public boolean doSearch(String query, String [] esIndex) {
        return doSearch(query, esIndex, "TOTAL" , "");
    }

    public boolean doSearch(String query, String [] esIndex, String service) {
        return doSearch(query, esIndex, service , "");
    }

    public int getSearchIdx(String idxName) {

        for(int idx = 0 ; idx < multiSearchIndex.size() ; idx++){
            if(multiSearchIndex.get(idx).equals(idxName)) {
                return idx;
            }
        }
        return -1;
    }



    /**
     * 설정된 값으로 조건을 조합하여   msearch 에 검색을 요청한다.
     * @param query     ::: 검색어
     * @param esIndex   ::: index List
     * @param addInfo   ::: 사용자 정보
     * @return
     */
    public boolean doSearch(String query, String [] esIndex, String service , String addInfo) {
        this.query = query;

		if ( esIndex == null || esIndex.length == 0 ) {
			esIndex = INDEX_LIST;
		}  
			 
		
        double took = System.currentTimeMillis();
        for ( int idx=0; idx < esIndex.length; idx++ ) {
            SearchRequest searchRequest = searchRequest(esIndex[idx]);
            multiSearchRequest.add(searchRequest);
            multiSearchIndex.put(esIndex[idx],idx);
        }

        boolean isSearch = msearch();

        took = ( System.currentTimeMillis() - took ) / 1000.0;
        //제일 오래 걸린 응답
        //double took = getMaxTook();

        //전체 카운트
        long totalCnt =  0 ;
        for (int i = 0; i < esIndex.length; i++) {
            totalCnt += getTotalHitsCount(i);
        }
        setQueryLog(query,service, took, totalCnt, addInfo);

        return isSearch;
    }




    public void setMapValue(String indexName, String type, String value) {
        searchMap.put(indexName + "@" + type, value );
    }


    /**
     * 필드값에 설정된 값을 리턴한다.
     * @param indexName
     * @param type
     * @return
     */
    public String getMapValue(String indexName, String type) {
        return  ProUtils.nvl(searchMap.get(indexName + "@" + type),"");
    }


    public SearchRequest searchRequest(String indexName) {


        if (  !"".equals(indexName) ) {

            SearchSourceBuilder searchBuilder = new SearchSourceBuilder();

            searchBuilder.trackTotalHits(true);


            String includeField = getMapValue(indexName , "INCLUDE");
            String excludeField = getMapValue(indexName , "EXCLUDE");

            if ( !"".equals(includeField) || !"".equals(excludeField) ) {
				if("".equals(includeField)){
					includeField ="*";
				}

                String [] includeFields = includeField.split(SPECIAL_CHAR_COMMA);
                String [] excludeFields = excludeField.split(SPECIAL_CHAR_COMMA);
				
                searchBuilder.fetchSource(includeFields, excludeFields);

                appendDebug("INCLUDE_FIELD : " + includeField );
                appendDebug("EXCLUDE_FIELD : " + excludeField );

            }

            String[] nestSearchFields = getMapValue(indexName ,"NEST_SEARCH").split(SPECIAL_CHAR_COMMA);
            String[] nestIncludeFields 	= getMapValue(indexName ,"NEST_INCLUDE").split(SPECIAL_CHAR_COMMA);
            String[] nestExcludeFields 	= getMapValue(indexName ,"NEST_EXCLUDE").split(SPECIAL_CHAR_COMMA);
            String[] nestHighlightFields 	= getMapValue(indexName ,"NEST_HIGHLIGHT").split(SPECIAL_CHAR_COMMA);

            String[] searchFields =  getMapValue(indexName , "SEARCH").split(SPECIAL_CHAR_COMMA);

/*
	public static final int DEFAULT_INDEX_NAME   	= 0;
	public static final int DEFAULT_ALIAS_NAME   	= 1;
	public static final int DEFAULT_SORT_FIELD 		= 2;
	public static final int DEFAULT_SEARCH_FIELD 	= 3;
	public static final int DEFAULT_EXCLUDE_FIELD 	= 4;
	public static final int DEFAULT_INCLUDE_FIELD 	= 5;
	public static final int DEFAULT_HIGHLIGHT_FIELD = 6;
	public static final int DEFAULT_FILTER_QUERY 	= 7;
	public static final int DEFAULT_INDEX_VIEW_NAME = 8;




*/
            BoolQueryBuilder boolQuery = new BoolQueryBuilder();
            BoolQueryBuilder searchQuery = new BoolQueryBuilder();
            {

                if ("".equals(query)) {
                    searchQuery.must(QueryBuilders.matchAllQuery());
                } else {
                    List<QueryBuilder> listQuery = getNestedSimpleQuery(nestSearchFields,nestHighlightFields,nestIncludeFields,nestExcludeFields, query, 1);
//                    List<QueryBuilder> listQuery = getNestedSimpleQuery(nestSearchFields, query, 1);
                    QueryBuilder common = getSimpleQuery(searchFields, query, 1);
					// simple query 를 사용
                    if (common != null) {
                        listQuery.add(common);
                    }

                    for (QueryBuilder qBuild : listQuery) {
                        searchQuery.should(qBuild);
                    }


                    //appendDebug("NEST_SEARCH_FIELD : " + getMapValue(indexName , "NEST_SEARCH") );
                    //appendDebug("SEARCH_FIELD : " + getMapValue(indexName , "SEARCH") );

                }
            }
            boolQuery.must(searchQuery);
			// searchRange에 필드명을 담으면 searchQuery 로 받아진다.


            String default_subject_fields = getMapValue(indexName ,"FIELD_SUBJECT");
            String value_subject		  = getMapValue(indexName ,"VALUE_SUBJECT");

            if ( !"".equals(default_subject_fields) && !"".equals(value_subject) ) {
                QueryBuilder common = getSimpleQuery(default_subject_fields, value_subject, 1);
                if (common != null) {
                    boolQuery.must(common);
                }
            }

            String default_body_fields = getMapValue(indexName ,"FIELD_BODY");
            String value_body		  = getMapValue(indexName ,"VALUE_BODY");

            if ( !"".equals(default_body_fields) && !"".equals(value_body) ) {

                QueryBuilder common = getSimpleQuery(default_body_fields, value_body, 1);
                if (common != null) {
                    boolQuery.must(common);
                }
            }

            String default_writer_fields = getMapValue(indexName ,"FIELD_WRITER");
            String value_writer		  = getMapValue(indexName ,"VALUE_WRITER");

            if ( !"".equals(default_writer_fields) && !"".equals(value_writer) ) {
                QueryBuilder common = getSimpleQuery(default_writer_fields, value_writer, 1);
                if (common != null) {
                    boolQuery.must(common);
                }
            }

            String default_attach_fields = getMapValue(indexName ,"FIELD_ATTACH");
            String value_attach		     = getMapValue(indexName ,"VALUE_ATTACH");


            if ( !"".equals(default_attach_fields) && !"".equals(value_attach) ) {
                QueryBuilder common = getSimpleQuery(default_attach_fields, value_attach, 1);
                if (common != null) {
                    boolQuery.must(common);
                }
            }

            String default_string_query	= getMapValue(indexName ,"QUERY_STRING");
            if ( !"".equals(default_string_query)  ) {

                if ( default_string_query.indexOf(",") != -1 ) {
                    String [] strs = ProUtils.split(default_string_query, SPECIAL_CHAR_COMMA);
                    for ( String str : strs ) {
                        QueryBuilder common = getTermQuery(str);
                        if (common != null) {
                            boolQuery.must(common);
                        }
                    }
                } else {

                    QueryBuilder common = getQueryString(default_string_query);
                    if (common != null) {
                        boolQuery.must(common);
                    }
                }
            }


            BoolQueryBuilder boolFilterQuery = null;
            String default_filter_query		  = getMapValue(indexName ,"FILTER_QUERY");

            if ( !"".equals(default_filter_query)  ) {

                QueryBuilder common = getQueryString(default_filter_query);
                if (common != null) {
                    if(boolFilterQuery == null){
                        boolFilterQuery = new BoolQueryBuilder();
                    }
                    boolFilterQuery.must(common);
                }

            }

            String default_not_query		  = getMapValue(indexName ,"NOT_QUERY");
            if ( !"".equals(default_not_query)  ) {
                QueryBuilder common = getQueryString(searchFields, default_not_query); //index의 선언한 sfield 를 대상으로 조회한다.
                if (common != null) {
                    if(boolFilterQuery == null){
                        boolFilterQuery = new BoolQueryBuilder();
                    }
                    boolFilterQuery.mustNot(common);
                }

            }


            /** VALUE_RANGE **/
            String[] valueRange =  getMapValue(indexName ,"VALUE_RANGE").split(SPECIAL_CHAR_COMMA);
            if ( valueRange != null && valueRange.length > 1 )
            {
                QueryBuilder rangeQueryBuilder = null;

                if (valueRange.length == 3) {
                    rangeQueryBuilder = getValueRange(valueRange[0], valueRange[1], valueRange[2]);
                } else if (valueRange.length == 4) {
                    rangeQueryBuilder = getValueRange(valueRange[0], valueRange[1], valueRange[2], valueRange[3]);
                } else if (valueRange.length == 6) {
                    rangeQueryBuilder = getValueRange(valueRange[0], valueRange[1], valueRange[2], valueRange[3], valueRange[4], valueRange[5]);
                }

                if(rangeQueryBuilder != null){
                    if(boolFilterQuery == null){
                        boolFilterQuery = new BoolQueryBuilder();
                    }
                    boolFilterQuery.must(rangeQueryBuilder);
                }
            }


            /** date Range **/
            String[] dateRange = getMapValue(indexName ,"DATE_RANGE").split(SPECIAL_CHAR_COMMA);
            if ( dateRange != null && dateRange.length > 1 ) {
                QueryBuilder rangeQueryBuilder = null;

                if ( dateRange.length == 3 ) {
                    rangeQueryBuilder = getValueRange(dateRange[0] , dateRange[1], dateRange[2]);
                } else if ( dateRange.length == 4 ) {
                    rangeQueryBuilder = getValueRange(dateRange[0] , dateRange[1], dateRange[2], dateRange[3]);
                } else if ( dateRange.length == 5 ) {
                    rangeQueryBuilder = getValueRange(dateRange[0] , dateRange[1], dateRange[2], dateRange[3], dateRange[4] ,"");
                } else if ( dateRange.length == 6 ) {
                    rangeQueryBuilder = getValueRange(dateRange[0] , dateRange[1], dateRange[2], dateRange[3], dateRange[4] ,valueRange[5]);
                } else {
                    appendERROR("DATE_RANGE is value split error  : " + dateRange.length );
                }
                if(rangeQueryBuilder != null){
                    if(boolFilterQuery == null){
                        boolFilterQuery = new BoolQueryBuilder();
                    }
                    boolFilterQuery.must(rangeQueryBuilder);
                }
            }


            String geoQuery = getMapValue(indexName ,"GEO_SEARCH");

            if(geoQuery != null && !"".equals(geoQuery) ){
                String [] geoQuerys = geoQuery.split(SPECIAL_CHAR_SLASH);
                QueryBuilder rangeQueryBuilder = null;
                GeoDistanceQueryBuilder geoFilter = new GeoDistanceQueryBuilder(geoQuerys[0]);
                geoFilter.point(Double.parseDouble(geoQuerys[1]), Double.parseDouble(geoQuerys[2]));//lat,lon
                geoFilter.distance(geoQuerys[3]);

                if(rangeQueryBuilder != null){
                    if(boolFilterQuery == null){
                        boolFilterQuery = new BoolQueryBuilder();
                    }
                    boolFilterQuery.must(geoFilter);
                }
            }

            if(boolFilterQuery != null){
                boolQuery.filter(boolFilterQuery);
            }

            searchBuilder.query(boolQuery);


            /* page setting */
            String [] arrPageField = getMapValue(indexName ,"PAGE").split(SPECIAL_CHAR_COMMA);
            if ( arrPageField != null &&  arrPageField.length == 2) {
                int from = ProUtils.parseInt(arrPageField[0], 0);
                int size = ProUtils.parseInt(arrPageField[1], 10);
                searchBuilder.from(from);
                searchBuilder.size(size);
                searchBuilder.explain(false);
            } else {
                searchBuilder.from(0);
                searchBuilder.size(10);
                searchBuilder.explain(false);
            }

            /* sort field setting */
            String [] sortFields = getMapValue(indexName ,"SORT").split(SPECIAL_CHAR_COMMA);
            if ( sortFields.length == 1 &&  "".equals(sortFields[0])  ) {
                searchBuilder.sort(new ScoreSortBuilder().order(SortOrder.DESC)); // <1>
            } else {
                for (int idx = 0; idx < sortFields.length; idx++) {
                    String [] arr = ProUtils.split(sortFields[idx],SPECIAL_CHAR_SLASH);
                    String _sort = arr[0];
                    String _order = "";
                    if ( arr.length == 1 ) {
                        _order = "DESC";
                    } else {
                        _order = arr[1];
                    }
                    if ("SCORE".equals(_sort) || "RANK".equals(_sort) ) {
                        searchBuilder.sort(new ScoreSortBuilder().order(SortOrder.DESC)); // <1>
                    }else if("GEO".equals(_sort) && arr.length>3)  {
                        double lon = Double.parseDouble(arr[2]);
                        double lat = Double.parseDouble(arr[3]);
                        GeoDistanceSortBuilder geoSort = new GeoDistanceSortBuilder( arr[1],lon, lat);
                        	      /*SortBuilders.geoDistanceSort( IndexingUtils.FIELD_LOCATION_NESTED ).unit( DistanceUnit.METERS )
                        	            .geoDistance(GeoDistance.SLOPPY_ARC).point(lat, lon);*/
                        geoSort.unit(DistanceUnit.METERS);
                        geoSort.geoDistance(GeoDistance.PLANE);
                        searchBuilder.sort(geoSort);
                    } else {
                        if ("ASC".equals(_order)) {
                            searchBuilder.sort(new FieldSortBuilder(_sort).order(SortOrder.ASC));  // <2>
                        } else {
                            searchBuilder.sort(new FieldSortBuilder(_sort).order(SortOrder.DESC));  // <2>
                        }
                    }
                }
                //appendDebug("SORT : " + getMapValue(indexName ,"SORT") );
            }
            /* highlight field setting */
            String strHighlightFields = getMapValue(indexName ,"HIGHLIGHT");
            if ( strHighlightFields != null && !"".equals(strHighlightFields) ) {
                HighlightBuilder highlighter = getHighlightList(strHighlightFields);
                searchBuilder.highlighter(highlighter);
                //appendDebug("HIGHLIGHT : " + getMapValue(indexName ,"HIGHLIGHT")  );
            }
            /* AGGREGATION_FIELD field setting */
            String  aggsField = getMapValue(indexName ,"AGGREGATION");
            if ( aggsField != null && !"".equals(aggsField)   ) {

                String [] aggsFields = aggsField.split(SPECIAL_CHAR_COMMA);
                for (int idx = 0; idx < aggsFields.length; idx++) {
                    searchBuilder.aggregation(getTermAggInfo("aggs_"+aggsFields[idx],aggsFields[idx],1000));
                }
                //appendDebug("AGGREGATION : " + getMapValue(indexName ,"AGGREGATION")  );
            }

            SearchRequest searchRequest = new SearchRequest();


            String aliasName = getMapValue(indexName ,"ALIAS");
            if(aliasName.indexOf(SPECIAL_CHAR_COMMA)>-1){
                String aliasIndexs[]=ProUtils.split(aliasName,SPECIAL_CHAR_COMMA);
                searchRequest.indices(aliasIndexs).source(searchBuilder);
            }else{
                searchRequest.indices(aliasName).source(searchBuilder);
            }

            
            appendDebug("GET " + searchRequest.indices()[0] + "/_search " + searchRequest.source().toString() + "" );

            return searchRequest;
        }

        return null;
    }


    /**
     * 숫자에 대한 범위 검색시 사용한다. 필드의 조건이 1개 인경우 처리
     * @param field   ::: 대상 필드명
     * @param start   ::: star 값
     * @param end     ::: end 값
     * @return
     */
    public QueryBuilder getValueRange(String field, String start, String end) {
        return getValueRange(field, "gte", start, "lte",end,"");
    }

    /**
     * 숫자에 대한 범위 검색시 사용한다. 필드의 조건이 1개이고 포멧을 설정한다.
     * @param field   ::: 대상 필드명
     * @param start   ::: 2번째 조건에 대한 Operation
     * @param end     ::: 시작 값
     * @param format  ::: 데이터 포멧을 설정한다.
     * @return
     */
    public QueryBuilder getValueRange(String field, String start, String end, String format) {
        return getValueRange(field, "gte", start, "lte",end ,format);
    }

    /**
     * 숫자에 대한 범위 검색시 사용한다. 필드의 조건이 2개 인경우 처리
     * @param field     ::: 대상 필드명
     * @param op1       ::: 2번째 조건에 대한 Operation
     * @param start     ::: 시작 값
     * @param op2       ::: 2번째 조건에 대한 Operation
     * @param end       ::: 끝값
     * @param format    ::: 데이터 포멧을 설정한다.
     * @return
     */
    public QueryBuilder getValueRange(String field, String op1, String start, String op2, String end, String format) {
        RangeQueryBuilder sQuery = QueryBuilders.rangeQuery(field);
        if(!"".equals(start.trim())) {
            if (op1.equals("gt")) {
                sQuery.gt(start);
            }
            if (op1.equals("gte")) {
                sQuery.gte(start);
            }
            if (op1.equals("lt")) {
                sQuery.lt(start);
            }
            if (op1.equals("lte")) {
                sQuery.lte(start);
            }
        }
        if(!"".equals(end.trim())) {
            if (op2.equals("gt")) {
                sQuery.gt(end);
            }
            if (op2.equals("gte")) {
                sQuery.gte(end);
            }
            if (op2.equals("lt")) {
                sQuery.lt(end);
            }
            if (op2.equals("lte")) {
                sQuery.lte(end);
            }
        }
        if(!"".equals(format.trim())) {
            sQuery.format(format);
        }
        return sQuery;
    }
    /**
     * 엘라스틱에 접속할 수 있는지 체크한다.
     * @param strUrl
     * @return
     */
    public boolean isConnect(String strUrl)  {
        appendDebug("Connection ElasticSearch Url : "+strUrl);
        HttpURLConnection urlConn = null;
        try {
            URL url = new URL(strUrl);
            urlConn = (HttpURLConnection) url.openConnection();
            urlConn.connect();
            if(HttpURLConnection.HTTP_OK== urlConn.getResponseCode()) {
                appendDebug("ElasticSearch Connection : True !");
                return true;
            } else {
                appendERROR("ElasticSearch Connection : False !");
            }
        } catch (Exception e) {
            appendERROR("ElasticSearch Connection Error : ["+e.toString()+"]");
            return false;
        } finally {
            urlConn.disconnect();
        }
        return false;
    }

    /**
     * simple Query 를 설정한다.
     * Field 에 Comma 를 기준으로 아래 배열로 만들어 리턴한다.
     * @param fields
     * @param query
     * @param andor
     * @return
     */
    public QueryBuilder getSimpleQuery(String fields, String query, int andor) {
        String [] fieldList = ProUtils.split(fields,SPECIAL_CHAR_COMMA);
		// 전달받은 fields를 , 로 스플릿해서 리스트로 담고 이걸 전달.
		// andor 는 논리 연산자 . 0이면 or 1이면 and
        return getSimpleQuery(fieldList,query,andor);
    }

    /**
     * simple Query 를 설정한다.
     * Field 에 Comma 를 기준으로 여러 필드들을 설정한다. ( String Array 기준 )
     * SLASH 를 기준으로 Field 의 가중치를 설정한다.
     * @param fields    ::: 필드명/가중치
     * @param query     ::: 검색어
     * @param andor     ::: 0=OR ::: 1=AND
     * @return
     */
    public QueryBuilder getSimpleQuery(String [] fields, String query, int andor) {
        Map<String, Float> fieldInfo = new HashMap<String, Float>();
        for(String field:fields) {
			// 만든 리스트를 하나씩 수행.
            if(field.indexOf(SPECIAL_CHAR_SLASH)>-1) {
				// 만약에 슬래시 를 포함하고 있다면
                String _field[]= ProUtils.split(field,SPECIAL_CHAR_SLASH);
				// 슬래시를 스플릿해서 _field에 담고.
                float boost = 1.0f;
				// f는 float 타입을 명시하기 위해 사용. 가중치 기본값은 1.0으로 지정.
                try {
                    boost = Float.parseFloat(_field[1]);
					// 필드명에 만약에 슬래시가 있다면 뒤에 숫자는 가중치를 의미.
                }catch(Exception ex) {
                    boost = 1.0f;
                }

                fieldInfo.put(_field[0], boost);
				// fieldInfo에 필드명과 가중치를 입력.
            }else {
                fieldInfo.put(field, 1.0f);
            }
        }
        Operator op = Operator.AND;
		// 기본은 and 검색.
        if(andor==0) {
            op = Operator.OR;
        }

        QueryBuilder queryBuilder = QueryBuilders
                                    .simpleQueryStringQuery(query)
                                    .fields(fieldInfo)
                                    .defaultOperator(op)
                                    .autoGenerateSynonymsPhraseQuery(true);
		// queryBuilder 로직은 엘라스틱서치 기본 로직.
		// simpleQueryStringQuery과 fields 와 defaultOperator 를 사용.
		// autoGenerateSynonymsPhraseQuery는 동의어 구문 쿼리 자동 생성하는 설정.
									
        return queryBuilder;
    }
	

    public QueryBuilder getQueryString(String query) {
        QueryBuilder queryBuilder = QueryBuilders.queryStringQuery(query);
        ((QueryStringQueryBuilder) queryBuilder).defaultOperator(Operator.AND)
                                                .type(MultiMatchQueryBuilder.Type.CROSS_FIELDS)
                                                .autoGenerateSynonymsPhraseQuery(true);
        return queryBuilder;
    }
	
    public QueryBuilder getQueryString(String field, String query) {
        return getQueryString(ProUtils.split(field,SPECIAL_CHAR_COMMA),query);
    }



	public QueryBuilder getQueryString(String [] fields, String query) {
		Map<String, Float> fieldInfo = new HashMap<String, Float>();
        for(String field:fields) {
            if(field.indexOf(SPECIAL_CHAR_SLASH)>-1) {
                String _field[]= ProUtils.split(field,SPECIAL_CHAR_SLASH);
                float boost = 1.0f;
                try {
                    boost = Float.parseFloat(_field[1]);
                }catch(Exception ex) {
                    boost = 1.0f;
                }

                fieldInfo.put(_field[0], boost);
            }else {
                fieldInfo.put(field, 1.0f);
            }
        }
		
        QueryBuilder queryBuilder = QueryBuilders
                                    .queryStringQuery(query)
                                    .fields(fieldInfo)
                                    .type(MultiMatchQueryBuilder.Type.CROSS_FIELDS)
                                    .autoGenerateSynonymsPhraseQuery(true);
		// 여기서는 queryStringQuery 를 사용 한다.
        return queryBuilder;
    }


    public List<QueryBuilder> getNestedSimpleQuery(String [] fieldList, String query, int andor) {

        List<QueryBuilder> listQuery = new ArrayList<QueryBuilder>();
        if(fieldList == null || fieldList.length==0 || fieldList[0].trim().equals("")) {
            return listQuery;
        }

        HashMap<String,String> _map = new HashMap<String,String>();
        for(String _field : fieldList) {
            String [] _fiedInfo = ProUtils.split(_field, SPECIAL_CHAR_DOT);
            if ( _fiedInfo != null ) {
                if(_map.containsKey(_fiedInfo[0])) {
                    _map.put(_fiedInfo[0], _map.get(_fiedInfo[0])+SPECIAL_CHAR_COMMA+_field);
                }else {
                    _map.put(_fiedInfo[0],_field);
                }
            }
        }
        for( Map.Entry<String, String> entry : _map.entrySet() ) {
            String key = entry.getKey();
            String value = entry.getValue();
            QueryBuilder sQuery = getSimpleQuery(value,query,andor);
            QueryBuilder queryBuilder = QueryBuilders.nestedQuery( key, sQuery, ScoreMode.None);
            listQuery.add(queryBuilder);
        }
        return listQuery;

    }

    public QueryBuilder getTermQuery(String str) {

        String[] arQuery = ProUtils.split(str,SPECIAL_CHAR_COLON);

        if ( arQuery.length == 1 ) {
            appendERROR("[getTermQuery] Invalid value [ " + str + " ]. Input the value [ fieldname:value1,value2,value3 ] ");
            return null;
        }

        String field = arQuery[0];
        String query = arQuery[1];

        String [] arQuerys = ProUtils.split(query," ");

        if("".equals(query.trim())) {
            return QueryBuilders.termsQuery(field, "");
        }
        Set<String> filter = new HashSet<String>();
        for(String _q : arQuerys) {
            if (_q != null && !_q.equals("")) {
                filter.add(_q);
            }
        }
        return QueryBuilders.termsQuery(field, filter);
    }




    public QueryBuilder getTermQuery(String field, String query) {
        if("".equals(query.trim())) {
            return QueryBuilders.termsQuery(field, "");
        }
        Set<String> filter = new HashSet<String>();
        filter.add(query);
        return QueryBuilders.termsQuery(field, filter);

    }


    /** 날짜검색을 셋팅한다.
     *
     * @param field         ::: 대상 필드명
     * @param start         ::: 시작 날짜
     * @param end           ::: 종료 날짜
     * @param format        ::: 날짜 포멧
     * @return
     */

/*
RangeQueryBuilder sQuery = QueryBuilders.rangeQuery("price")
    .gte(10)   // 가격이 10 이상
    .lte(100); // 가격이 100 이하
	=>> 기본적으로 엘라스틱서치에서 제공하는 로직
*/

    public QueryBuilder getDateRange(String field, String start, String end, String format) {
        RangeQueryBuilder sQuery = QueryBuilders.rangeQuery(field);
        if(!"".equals(start.trim())) {
            sQuery.gte(start);
        }
        if(!"".equals(end.trim())) {
            sQuery.lte(end);
        }
        if(!"".equals(format.trim())) {
            sQuery.format(format);
        }
        return sQuery;
    }


    /**
     * highlight 관련 설정을 진행한다.
     * @param searchField
     * @return
     */
    public HighlightBuilder getHighlightList(String searchField) {
        return getHighlightList(searchField,"experimental", "scan");
    }

    /**
     * highlight 관련 설정을 진행한다.
     * @param searchField
     * @return
     */
    public HighlightBuilder getHighlightList(String searchField, String highlighterType, String fragmenter) {
        String [] searchFields = ProUtils.split(searchField,SPECIAL_CHAR_COMMA);
        return getHighlightList(searchFields,highlighterType, fragmenter);
    }

    /**
     * Highlight 관련 설정을 진행한다.
     * @param searchField       ::: 필드명
     * @param highlighterType   ::: 하이라이트 타입
     * @param fragmenter        ::: 분석방식
     * @return
     */
    public HighlightBuilder getHighlightList(String [] searchField, String highlighterType, String fragmenter ) {

        HighlightBuilder highlightBuilder = new HighlightBuilder();
        for ( String sfield: searchField) {
            int maxSize = HIGHLIGHT_SIZE;
            if(sfield.indexOf(SPECIAL_CHAR_SLASH)>-1) {
                String _sInfo[] = ProUtils.split(sfield, SPECIAL_CHAR_SLASH);
                sfield = _sInfo[0];
                maxSize =  ProUtils.parseInt(_sInfo[1], maxSize);
            }
            HighlightBuilder.Field highlighField = new HighlightBuilder.Field(sfield);
            highlighField.fragmentSize(maxSize);
            highlighField.noMatchSize(maxSize);
            highlightBuilder.field(highlighField);
        }
        highlightBuilder.preTags("<em>");
        highlightBuilder.postTags("</em>");
        if ( highlighterType != null || !"".equals(highlighterType) )
            highlightBuilder.highlighterType(highlighterType);

        if ( fragmenter != null || !"".equals(fragmenter) )
            highlightBuilder.fragmenter(fragmenter);

        highlightBuilder.order(HighlightBuilder.Order.SCORE);
        return highlightBuilder;
    }

    /**
     * 검색필드에 추가적인 .korean .exact 필드가 추가 되었을 경우 확장하는 메소드이다.
     * @param searchField
     * @param mSearchField
     * @return
     */

    public String setSearchFieldExtends(String searchField,String mSearchField){
        if("".equals(searchField)) {
            return "";
        }

        StringBuilder sb = new StringBuilder();
        mSearchField = SPECIAL_CHAR_COMMA+mSearchField+SPECIAL_CHAR_COMMA;
        String[] appSearch = ProUtils.split(searchField, SPECIAL_CHAR_COMMA);
        for(String _search:appSearch ) {
            if(sb.length()!=0) {
                sb.append(SPECIAL_CHAR_COMMA);
            }
            if(mSearchField.indexOf(SPECIAL_CHAR_COMMA+_search+SPECIAL_CHAR_COMMA)>-1) {
                sb.append(_search);
                sb.append(SPECIAL_CHAR_COMMA);
                sb.append(_search+".korean");
                sb.append(SPECIAL_CHAR_COMMA);
                sb.append(_search+".exact");
            } else {
                sb.append(_search);
            }
        }

        String ret =  sb.toString();
        sb.setLength(0);
        return ret;
    }

    /**
     * simple Query 를 설정한다.
     * Field 에 Comma 를 기준으로 여러 필드들을 설정한다. ( String Array 기준 )
     * SLASH 를 기준으로 Field 의 가중치를 설정한다.
     * @param fields    ::: 필드명/가중치
     * @param query     ::: 검색어
     * @param andor     ::: 0=OR ::: 1=AND
     * @return
     */

	public List<QueryBuilder> getNestedSimpleQuery(String fields,String highField,String inField,String exField, String query, int andor) {
		String fieldList[]=ProUtils.split(fields, SPECIAL_CHAR_COMMA);
		String highFieldList[]=ProUtils.split(inField, SPECIAL_CHAR_COMMA);
		String inFieldList[]=ProUtils.split(inField, SPECIAL_CHAR_COMMA);
		String exFieldList[]=ProUtils.split(exField, SPECIAL_CHAR_COMMA);

		return getNestedSimpleQuery( fieldList,highFieldList,inFieldList,exFieldList,  query,  andor);
	}

    public List<QueryBuilder> getNestedSimpleQuery(String[] fieldList,String[] highField,String[] inField,String[] exField, String query, int andor) {

        List<QueryBuilder> listQuery = new ArrayList<QueryBuilder>();
        if(fieldList == null || fieldList.length==0 || fieldList[0].trim().equals("")) {
            return listQuery;
        }
        //= psProperties.SEARCH_INDEX_SETS[indexIdx][VALUE_ATTACH];
        HashMap<String,String> _map = new HashMap<String,String>();

		HashMap<String,String> _mapInclude = new HashMap<String,String>();
		HashMap<String,String> _mapExclude = new HashMap<String,String>();
		HashMap<String,String> _mapHighlight = new HashMap<String,String>();
		for(String _field : fieldList) {
			if("".equals(_field)) {
				continue;
			}
            String [] _fiedInfo = ProUtils.split(_field, SPECIAL_CHAR_DOT);
			if ( _fiedInfo != null ) {
                if(_map.containsKey(_fiedInfo[0])) {
                	_map.put(_fiedInfo[0], _map.get(_fiedInfo[0])+SPECIAL_CHAR_COMMA+_field);
                }else {
                	_map.put(_fiedInfo[0], _field);
                }
            }
        }

		for(String _field : highField) {
			if("".equals(_field)) {
				continue;
			}
            String [] _fiedInfo = ProUtils.split(_field, SPECIAL_CHAR_DOT);
			if ( _fiedInfo != null ) {
                if(_mapHighlight.containsKey(_fiedInfo[0])) {
                	_mapHighlight.put(_fiedInfo[0], _mapHighlight.get(_fiedInfo[0])+SPECIAL_CHAR_COMMA+_field);
                }else {
                	_mapHighlight.put(_fiedInfo[0], _field);
                }
            }
        }

		for(String _field : inField) {
			if("".equals(_field)) {
				continue;
			}
            String [] _fiedInfo = ProUtils.split(_field, SPECIAL_CHAR_DOT);
			if ( _fiedInfo != null ) {
                if(_mapInclude.containsKey(_fiedInfo[0])) {
                	_mapInclude.put(_fiedInfo[0], _mapInclude.get(_fiedInfo[0])+SPECIAL_CHAR_COMMA+_field);
                }else {
                	_mapInclude.put(_fiedInfo[0], _field);
                }
            }
        }

		for(String _field : exField) {
			if("".equals(_field)) {
				continue;
			}
            String [] _fiedInfo = ProUtils.split(_field, SPECIAL_CHAR_DOT);
			if ( _fiedInfo != null ) {
                if(_mapExclude.containsKey(_fiedInfo[0])) {
                	_mapExclude.put(_fiedInfo[0], _mapExclude.get(_fiedInfo[0])+SPECIAL_CHAR_COMMA+_field);
                }else {
                	_mapExclude.put(_fiedInfo[0], _field);
                }
            }
        }

        for( Map.Entry<String, String> entry : _map.entrySet() ) {
            String key = entry.getKey();
            String value = entry.getValue();
            QueryBuilder sQuery = getSimpleQuery(value,query,andor);
			InnerHitBuilder innerHitBuilder = null;
			QueryBuilder queryBuilder = null;
			if(_mapInclude.containsKey(key)||_mapExclude.containsKey(key)||_mapHighlight.containsKey(key)) {
				innerHitBuilder = new InnerHitBuilder();
				if(_mapInclude.containsKey(key)||_mapExclude.containsKey(key)) {
					String includeFieldList[] = ProUtils.split(_mapInclude.get(key), SPECIAL_CHAR_COMMA);
					String excludeFieldList[] = ProUtils.split(_mapExclude.get(key), SPECIAL_CHAR_COMMA);
					FetchSourceContext fetchSourceContext = new FetchSourceContext(true, includeFieldList, excludeFieldList);
					innerHitBuilder.setFetchSourceContext(fetchSourceContext);
				}
				//for(String _field : innerhitfieldList) {
				//	innerHitBuilder.addDocValueField(_field,"use_field_mapping");
				//}
				if(_mapHighlight.containsKey(key)) {
					innerHitBuilder.setHighlightBuilder(getHighlightList(_mapHighlight.get(key)));
				}
				//queryBuilder = QueryBuilders.nestedQuery( key, sQuery, ScoreMode.None);
				NestedQueryBuilder nestBuilder = new NestedQueryBuilder( key, sQuery, ScoreMode.None);
				nestBuilder.innerHit(innerHitBuilder);
				listQuery.add(nestBuilder);
			}else{
				queryBuilder = QueryBuilders.nestedQuery( key, sQuery, ScoreMode.None);
				 listQuery.add(queryBuilder);
			}



        }
        return listQuery;

    }


    public QueryBuilder getNSimpleQuery(String field,String query,int andor) {
        String _fieldInfo[]=ProUtils.split(field, ".");
        String path = _fieldInfo[0];
        return getNestedSimpleQuery(path, field,query,andor);
    }

    public QueryBuilder getNestedSimpleQuery(String path,String fields,String query,int andor) {
        QueryBuilder sQuery = getSimpleQuery(fields,query,andor);
        QueryBuilder queryBuilder = QueryBuilders.nestedQuery(path, sQuery, ScoreMode.Total);
        return queryBuilder;
    }




    /**
     * single index search ;
     *
     * @param searchRequest
     * @return
     */

    public SearchResponse search(SearchRequest searchRequest) {
        SearchResponse searchResponse = null;
        try {
            searchResponse = client.search(searchRequest, RequestOptions.DEFAULT);
        } catch (IOException e) {
            appendERROR("[search]" + e.getMessage());
        }
        return searchResponse;
    }

    /**
     * Multi index , type search ;;
     *
     * @param searchRequest
     * @return
     */
    public MultiSearchResponse msearch(MultiSearchRequest searchRequest) {
        MultiSearchResponse searchResponse = null;
        try {
            searchResponse = client.msearch(searchRequest, RequestOptions.DEFAULT);
        } catch (IOException e) {
            appendERROR("[msearch]" + e.getMessage());
        }
        return searchResponse;
    }

    /**
     * Multi index , type search ;;
     *
     * @return boolean
     */
    public boolean msearch() {
        try {

            if ( client == null ) connection();

            this.multiSearchResponse = client.msearch(this.multiSearchRequest, RequestOptions.DEFAULT);
            //appendDebug("[multiSearchResponse]" + multiSearchResponse.getResponses()[0].getResponse().toString());
            return true;
        }catch(Exception e) {
            appendERROR("[msearch]" + e.getMessage());
            return false;
        }
    }


    /**
     * Stores <code>fieldValue</code> as a search term on the
     * <code>fieldName</code> field.
     *
     * @param fieldName  the field name
     * @param fieldValue the field value
     * @param clean      <code>true</code> to escape solr special characters in the field
     *                   value
     */
    /**
     protected void and(String fieldName, Object fieldValue, boolean clean) {

     fieldName = fieldName.trim();

     // Make sure the data structures are set up accordingly
     if (searchTerms == null)
     searchTerms = new HashMap<String, Set<Object>>();
     Set<Object> termValues = searchTerms.get(fieldName);
     if (termValues == null) {
     termValues = new HashSet<Object>();
     searchTerms.put(fieldName, termValues);
     }

     // Add the term
     termValues.add(fieldValue);
     }
     */

    public String getAliasName(String index) {
        return getMapValue(index, "ALIAS_NAME");
    }
    /**
     * multi 검색시 검색 Index를 리턴한다.
     */
    public int getMultiIdx(String index){
        Object obj = multiSearchIndex.get(index);
        if(obj==null){
            return -1;
        }
        return (int)obj;
    }

    public MultiSearchRequest getMultiSearchRequest() {
        return this.multiSearchRequest;
    }


    public MultiSearchResponse getMultiSearchResponse(){
        return  this.multiSearchResponse;
    }





    /**
     * index 의 idx 로 가져온 건수를 가져온다.
     * @param indexIdx
     * @return
     */

    public long getHitsCount(int indexIdx) {
        long ret = -1;
        if ( this.multiSearchResponse != null ) {
            MultiSearchResponse.Item item = multiSearchResponse.getResponses()[indexIdx];
            if(!item.isFailure()) {
                SearchHit[] hits = item.getResponse().getHits().getHits();
                ret = Long.valueOf(hits.length);
            } else {
                appendERROR("[getHitsCount] " + item.getFailureMessage());
            }
            //appendDebug("indexIdx= "  + indexIdx + " / TotalCount=" + ret);
        }

        return ret;
    }
    /**
     * index idx 로 전체 건수를 가져온다.
     * @param indexIdx
     * @return
     */
    public long getTotalHitsCount(String index) {

        long ret = -1;
		
		int indexIdx = getMultiIdx(index);
		
        if ( this.multiSearchResponse != null ) {

            MultiSearchResponse.Item item = multiSearchResponse.getResponses()[indexIdx];
            if(!item.isFailure()) {
                ret = item.getResponse().getHits().getTotalHits().value;
            } else {
                appendERROR("[getTotalHitsCount] " + item.getFailureMessage());
            }
            //appendDebug("indexIdx= "  + indexIdx + " / TotalCount=" + ret);
        }

        return ret;
    }
    /**
     * index idx 로 전체 건수를 가져온다.
     * @param indexIdx
     * @return
     */
    public long getTotalHitsCount(int indexIdx) {

        long ret = -1;
        if ( this.multiSearchResponse != null ) {

            MultiSearchResponse.Item item = multiSearchResponse.getResponses()[indexIdx];
            if(!item.isFailure()) {
                ret = item.getResponse().getHits().getTotalHits().value;
            } else {
                appendERROR("[getTotalHitsCount] " + item.getFailureMessage());
            }
            //appendDebug("indexIdx= "  + indexIdx + " / TotalCount=" + ret);
        }

        return ret;
    }

    /**
     * 필드 Data 를 가져온다.
     * @param hit
     * @param fieldName
     * @param def
     * @param isHighlight
     * @return
     */

    public String getFieldData( SearchHit hit, String fieldName, Object def , boolean isHighlight) {
        Map<String, Object> map = hit.getSourceAsMap();

        String _ret = null;

        if(isHighlight) {
            Map<String, HighlightField> _highMap = hit.getHighlightFields();
            HighlightField hlObj = _highMap.get(fieldName);

            if(hlObj !=null) {
                Text[] objss =hlObj.getFragments();
                if(objss!=null && objss.length>0) {
                    _ret = objss[0].toString();
                }else {
                    _ret = String.valueOf(map.getOrDefault(fieldName,def));
                }
            }else {
                _ret = String.valueOf(map.getOrDefault(fieldName,def));
            }

        }else {
            _ret = String.valueOf(map.getOrDefault(fieldName,def));
        }


        return _ret;
    }


    public String getFieldData( SearchHit hit , String field, Object def ) {
        Map<String, Object> map = hit.getSourceAsMap();
        String _ret = null;
        Map<String, HighlightField> _highMap = hit.getHighlightFields();
		
        HighlightField hlObj = _highMap.get(field);
        if(hlObj !=null) {
            Text[] objss =hlObj.getFragments();
            if(objss!=null && objss.length>0) {
                _ret = objss[0].toString();
            }else {
                _ret = String.valueOf(map.getOrDefault(field,def));
            }
        }else {
            _ret = String.valueOf(map.getOrDefault(field,def));
        }


        return _ret;
    }


    /**
     * index 이름으로 가져온 시간을 가져온다.
     * @param indexName
     * @return
     */
    public long getTook(String indexName)
    {

        int indexIdx = getMultiIdx(indexName);
        long ret = -1;

        try {
            if ( this.multiSearchResponse != null ) {
                MultiSearchResponse.Item [] items = this.multiSearchResponse.getResponses();
                MultiSearchResponse.Item item = this.multiSearchResponse.getResponses()[indexIdx];
                TimeValue time = item.getResponse().getTook();
                ret = time.getMillis();
            }
        } catch ( Exception e) {
        }

        return ret;
    }




    /**
     * 경고 메시지를 버퍼에 저장한다.
     * @param msg 경고 메시지
     */
    public void appendWARN(String msg) {
        if(isDebug && !msg.equals("")){
            warnMsgBuffer.append("[WARN]" + msg + "\n");
        }
    }


    /**
     * 경고 메시지를 버퍼에 저장한다.
     * @param msg 경고 메시지
     */
    public void appendDebug(String msg) {
        if(isDebug && !msg.equals("")){
            debugMsgBuffer.append("[DEBUG] " + msg + "\n");
        }
    }

    /**
     * 에러 메시지를 버퍼에 저장한다.
     * @param msg 에러 메시지
     */
    public void appendERROR(String msg) {
        if(!msg.equals("")){
            errorMsgBuffer.append("[ERROR] " + msg + "\n");
        }
    }

    /**
     * 디버그 정보를 화면에 출력할 경우 메시지를 반환한다.
     * @return 디버그 정보 반환
     */
    public String printDebugView() {
        StringBuffer outBuffer = new StringBuffer();
        if ( !"".equals(errorMsgBuffer.toString() ) ) {
            outBuffer.append(errorMsgBuffer.toString());
        }
        if ( !"".equals(warnMsgBuffer.toString() ) )  {
            outBuffer.append(warnMsgBuffer.toString() );
        }
        if ( !"".equals(debugMsgBuffer.toString() ) )  {
            outBuffer.append( debugMsgBuffer.toString() );
        }

        return outBuffer.toString();
    }


    /**
     * 디버그 정보를 화면에 출력할 경우 메시지를 반환한다.
     * @return 디버그 정보 반환
     */
    public String printDebugView(String type) {

        StringBuffer outBuffer = new StringBuffer();

        if ( !"".equals(errorMsgBuffer.toString() ) && ( "error".equals(type) || "debug".equals(type) ) )  {
            outBuffer.append(  errorMsgBuffer.toString()  );
        }
        if ( !"".equals(warnMsgBuffer.toString() ) && ( "warn".equals(type) || "debug".equals(type) ) )  {
            outBuffer.append(  warnMsgBuffer.toString()  );
        }
        if ( !"".equals(debugMsgBuffer.toString() ) && ( "debug".equals(type) ) )   {
            outBuffer.append(  debugMsgBuffer.toString() );
        }

        return outBuffer.toString();
    }

    public String setParameterLog(String addId, String params) {
		
		String id = addId + "_" + ProUtils.getCurrentDate("yyyyMMddHHmmssSSS");
        try {
            params = URLEncoder.encode(params, "UTF-8");
        } catch(Exception e) {
			
		}

        String url = "http://" + MANAGER_SERVERS + "/service/RealtimeService.ps";
        String param = "?id=" + id + "&body=" + params;
        return callPluginAPI2(url + param, "");
    }

    public String setQueryLog(String query, String index, double took,long total,String userId) {

        try {
            query = URLEncoder.encode(query, "UTF-8");
        } catch(Exception e) {
			
		}

        String url = "http://" + ES_SERVERS + "/_pro10-querylog";
        String params = "?query=" + query + "&service=" + index + "&cnt=" + total + "&took=" + took + "&addinfo=" + userId ;
        return callPluginAPI2(url + params, "");
    }

  
    public String callPluginAPI2(String url, String params) {

        StringBuffer receiveMsg = new StringBuffer();
        HttpURLConnection uc = null;
        try {
            URL servletUrl = new URL(url);
            uc = (HttpURLConnection) servletUrl.openConnection();
            uc.setRequestProperty("Content-type", "application/x-www-form-urlencoded");
            uc.setRequestMethod("POST");
            uc.setDoOutput(true);
            uc.setDoInput(true);
            uc.setUseCaches(false);
            uc.setDefaultUseCaches(false);
            DataOutputStream dos = new DataOutputStream (uc.getOutputStream());
            dos.write(params.getBytes());
            dos.flush();
            dos.close();

            int errorCode = 0;

//			logger.info("[URLConnection Response Code] " + uc.getResponseCode() + " ::" + HttpURLConnection.HTTP_OK);

            if (uc.getResponseCode() == HttpURLConnection.HTTP_OK) {
                String currLine = "";
                // UTF-8. ..
                BufferedReader in = new BufferedReader(new InputStreamReader(uc.getInputStream(), "UTF-8"));
                while ((currLine = in.readLine()) != null) {
                    receiveMsg.append(currLine).append("\r\n");
                }

//				logger.info("receiveMsg=" + receiveMsg.toString());
                in.close();
            } else {
                errorCode = uc.getResponseCode();
                return receiveMsg.toString();
            }
        } catch(Exception ex) {
//        	logger.error(ex);
        } finally {
            uc.disconnect();
        }
        return receiveMsg.toString();
    }

    public AggregationBuilder getGroupAggInfo(String aggType,String aggName,String field) throws Exception {
        //groupMap.put(aggName, new KVValue("FIELD", parent));
        AggregationBuilder builder=null;

        switch (aggType.toUpperCase()) {
            case "SUM":
                builder = AggregationBuilders.sum(aggName).field(field);
                break;
            case "MAX":
                builder = AggregationBuilders.max(aggName).field(field);
                break;
            case "MIN":
                builder = AggregationBuilders.min(aggName).field(field);
                break;
            case "AVG":
                builder = AggregationBuilders.avg(aggName).field(field);
                break;
            case "STATS":
                builder = AggregationBuilders.stats(aggName).field(field);
                break;
            case "EXTENDED_STATS":
                builder = AggregationBuilders.extendedStats(aggName).field(field);
                break;
            case "PERCENTILES":
                builder = AggregationBuilders.percentiles(aggName).field(field);
                //case "TOPHITS":
                //    return makeTopHitsAgg(field);
                //case "SCRIPTED_METRIC":
                //     return scriptedMetric(field);
            case "COUNT":
                builder = AggregationBuilders.count(aggName).field(field);

            default:
                throw new Exception("the agg function not to define !");
        }
        return builder;
    }

    public TermsAggregationBuilder getTermAggInfo(String aggName,String termFields,int rownum) {

        TermsAggregationBuilder aggregation = AggregationBuilders.terms(aggName);

        aggregation.field(termFields);
        aggregation.size(rownum);

        return aggregation;

    }

    public List<Map<String,Object>>  getAggsList( int indexIdx,String aggName,String aggSubName) {

        List<Map<String,Object>> inputList = new ArrayList<>();

        //appendDebug("[getAggsList] aggsindexIdx : "  + indexIdx );
        //appendDebug("[getAggsList] aggs : "  + multiSearchResponse.getResponses()[indexIdx]);
        //appendDebug("[getAggsList] aggResponse : "  + multiSearchResponse.getResponses()[indexIdx].getResponse());
        //appendDebug("[getAggsList] aggAggregation : "  + multiSearchResponse.getResponses()[indexIdx].getResponse().getAggregations());

        if(indexIdx<0 || multiSearchResponse.getResponses().length<=indexIdx ){
            appendERROR("[getAggsList] indexIdx < 0");
            //경고문 작성
            return inputList;
        }
        if(multiSearchResponse.getResponses()[indexIdx] == null
                ||multiSearchResponse.getResponses()[indexIdx].getResponse()==null
                ||multiSearchResponse.getResponses()[indexIdx].getResponse().getAggregations()==null
                ||multiSearchResponse.getResponses()[indexIdx].getResponse().getAggregations().get("aggs_" +aggName)==null){
            appendERROR("[getAggsList] multiSearchResponse.getResponses() is null ");
            //경고문 작성
            return inputList;
        }
        Aggregation  aggs = multiSearchResponse.getResponses()[indexIdx].getResponse().getAggregations().get("aggs_" + aggName);
        //appendDebug("aggs_"+aggs);
        List<Terms.Bucket> buckList =(List<Terms.Bucket>) ((Terms) aggs).getBuckets();

        //appendDebug("[getAggsList] buckList : "  + buckList);

        int cnt = 0;
        for (Terms.Bucket bk : buckList) {
            String key = (String) bk.getKeyAsString();
            long count = bk.getDocCount();

            Map<String,Object> auto = new LinkedHashMap<>();
            auto.put("key", key);
            auto.put("count", count);

            if(!"".equals(aggSubName)) {
                Aggregations subAggs = bk.getAggregations() ;

                Terms subaggs =  subAggs.get(aggSubName);
                if(subaggs!=null) {
                    List<Terms.Bucket> subBuckList = (List<Terms.Bucket>) subaggs.getBuckets();
                    List<Map<String,Object>> subList = new ArrayList<>();
                    for (Terms.Bucket subBuck : subBuckList) {
                        String subKey = (String) subBuck.getKeyAsString();
                        long subCount = subBuck.getDocCount();
                        Map<String,Object> aggSubMap = new LinkedHashMap<>();
                        aggSubMap.put("key", subKey);
                        aggSubMap.put("count", subCount);
                        subList.add(aggSubMap);
                    }
                    auto.put("sublist",subList);
                }
            }
            inputList.add(auto);

        }

        return inputList;
    }




    /**
     * 필드 Nested Data 를 가져온다. file.fileid,file.filename,file.attach일 경우
     * @param hit
     * @param nestedName NestField명 (file)
     * @param nestedKey NestedField의 고유키-  하이라이팅 연결 되는 키  ( fileid )
     * @param fieldNames 필드값 (filename,summary:attach )  ** summary:attach summary 파일 내용을 요약한 부분이고 attach는 진짜 하일라이팅 되는 필드
     * @param def 기본값
     * @param isHighlight
     * @return
     */

    public Object getNestedData( SearchHit hit,String nestedName,String nestedKey, String fieldNames, Object def , boolean isHighlight ,String innerHit) {
        Map<String, Object> map = hit.getSourceAsMap();
        Map<String, SearchHits> innerMap =	hit.getInnerHits();

        SearchHit[] innerHits = null;
        SearchHits innerObject = null;
        if(innerMap!=null) {
            innerObject = innerMap.get(nestedName);
        }
        if(innerObject!=null) {
            innerHits = innerObject.getHits();
        }
        Object _ret = null;
        Object _nestObj = map.getOrDefault(nestedName,def);
        String filedList[]=ProUtils.split(fieldNames, ",");
        List<Map<String, Object>> _retList =new ArrayList<Map<String, Object>>();
        if(_nestObj instanceof List<?>) {
            List<Map<String, Object>> _nestList = (List<Map<String, Object>>)_nestObj;

            if("1".equals(innerHit)) {
                for(Map<String, Object> _data : _nestList){
                    Map<String, Object> _retData = new HashMap<String, Object>();
                    String _keyValue =String.valueOf(_data.getOrDefault(nestedKey, ""));
                    for(String _fieldName : filedList) {
                        String aliasInfos[]=ProUtils.split(_fieldName, ":");
                        String defaultField = "";
                        String fieldValueName = "";
                        String _value = "";
                        if(aliasInfos.length>2) {
                            _fieldName = aliasInfos[0];
                            defaultField = aliasInfos[1];
                            fieldValueName = aliasInfos[2];
                        }else if(aliasInfos.length>1) {
                            _fieldName = aliasInfos[0];
                            defaultField = aliasInfos[1];
                            fieldValueName = _fieldName;
                        }else {
                            _fieldName = aliasInfos[0];
                            defaultField = _fieldName;
                            fieldValueName = defaultField;
                        }

                        if(innerHits!=null && isHighlight) {
                            for(SearchHit _innerHit : innerHits) {
                                Map<String, Object> _innermap = _innerHit.getSourceAsMap();
                                String _innerkey = String.valueOf(_innermap.getOrDefault(nestedKey, ""));
                                if(!"".equals(_keyValue) && _innerkey.equals(_keyValue)) {
                                    Map<String, HighlightField> _highMap = _innerHit.getHighlightFields();
                                    HighlightField hlObj = _highMap.get(nestedName+"."+_fieldName);
                                    if(hlObj !=null) {
                                        Text[] objss =hlObj.getFragments();
                                        if(objss!=null && objss.length>0) {
                                            _value = objss[0].toString();
                                            break;
                                        }
                                    }
                                }
                            }

                        }else {
                            _value = String.valueOf(_data.getOrDefault(_fieldName, ""));

                        }
                        if("".equals(_value)) {
                            _value = String.valueOf(_data.getOrDefault(defaultField, ""));
                        }
                        _retData.put(fieldValueName,_value );
                    }



                    _retList.add(_retData);
                }
            }else {
                if(innerHits!=null) {
                    for(SearchHit _innerHit : innerHits) {
                        Map<String, Object> _innermap = _innerHit.getSourceAsMap();
                        String _innerkey = String.valueOf(_innermap.getOrDefault(nestedKey, ""));
                        for(Map<String, Object> _data : _nestList){
                            Map<String, Object> _retData = new HashMap<String, Object>();
                            String _keyValue =String.valueOf(_data.getOrDefault(nestedKey, ""));

                            if(!"".equals(_keyValue) && _innerkey.equals(_keyValue)) {
                                String _value = "";
                                for(String _fieldName : filedList) {
                                    String aliasInfos[]=ProUtils.split(_fieldName, ":");
                                    String defaultField = "";
                                    String fieldValueName = "";

                                    if(aliasInfos.length>2) {
                                        _fieldName = aliasInfos[0];
                                        defaultField = aliasInfos[1];
                                        fieldValueName = aliasInfos[2];
                                    }else if(aliasInfos.length>1) {
                                        _fieldName = aliasInfos[0];
                                        defaultField = aliasInfos[1];
                                        fieldValueName = _fieldName;
                                    }else {
                                        _fieldName = aliasInfos[0];
                                        defaultField = _fieldName;
                                        fieldValueName = defaultField;
                                    }

                                    Map<String, HighlightField> _highMap = _innerHit.getHighlightFields();

                                    HighlightField hlObj = _highMap.get(nestedName+"."+_fieldName);
                                    if(hlObj !=null) {
                                        Text[] objss =hlObj.getFragments();
                                        if(objss!=null && objss.length>0) {
                                            _value = objss[0].toString();
                                        }
                                    }
                                    if("".equals(_value)) {
                                        _value = String.valueOf(_data.getOrDefault(defaultField, ""));
                                    }

                                    _retData.put(fieldValueName,_value );
                                }
                                _retList.add(_retData);
                            }
                        }
                    }
                }
            }
            return _retList;
        }else{
            _ret = map.getOrDefault(nestedName,def);
        }

        return _ret;
    }



    public  boolean isNestedCheck( SearchHit hit,String nestedName) {
        Map<String, Object> map = hit.getSourceAsMap();
        Map<String, SearchHits> innerMap =	hit.getInnerHits();

        SearchHit[] innerHits = null;
        SearchHits innerObject = null;
        if(innerMap!=null) {
            innerObject = innerMap.get(nestedName);
        }
        if(innerObject!=null) {
            innerHits = innerObject.getHits();

            if(innerHits!=null && innerHits.length>0){
                return true;
            }
        }
        return false;
    }


    public  List<Map<String, String>> getListData( SearchHit hit,String nestedName,String nestedKey, String fieldNames, Object def , boolean isHighlight ,String innerHit) {
        Map<String, Object> map = hit.getSourceAsMap();
        Map<String, SearchHits> innerMap =	hit.getInnerHits();

        SearchHit[] innerHits = null;
        SearchHits innerObject = null;
        if(innerMap!=null) {
            innerObject = innerMap.get(nestedName);
        }
        if(innerObject!=null) {
            innerHits = innerObject.getHits();
        }

        Object _nestObj = map.getOrDefault(nestedName,def);
        String filedList[]=ProUtils.split(fieldNames, ",");
        List<Map<String, String>> _retList =new ArrayList<Map<String, String>>();
        if(_nestObj instanceof List<?>){
            List<Map<String, Object>> _nestList = (List<Map<String, Object>>)_nestObj;

            if("1".equals(innerHit)) {
                for(Map<String, Object> _data : _nestList){
                    Map<String, String> _retData = new HashMap<String, String>();
                    String _keyValue =String.valueOf(_data.getOrDefault(nestedKey, ""));
                    for(String _fieldName : filedList) {
                        String aliasInfos[]=ProUtils.split(_fieldName, ":");
                        String defaultField = "";
                        String fieldValueName = "";
                        String _value = "";
                        if(aliasInfos.length>2) {
                            _fieldName = aliasInfos[0];
                            defaultField = aliasInfos[1];
                            fieldValueName = aliasInfos[2];
                        }else if(aliasInfos.length>1) {
                            _fieldName = aliasInfos[0];
                            defaultField = aliasInfos[1];
                            fieldValueName = _fieldName;
                        }else {
                            _fieldName = aliasInfos[0];
                            defaultField = _fieldName;
                            fieldValueName = defaultField;
                        }

                        if(innerHits!=null && isHighlight) {
                            for(SearchHit _innerHit : innerHits) {
                                Map<String, Object> _innermap = _innerHit.getSourceAsMap();
                                String _innerkey = String.valueOf(_innermap.getOrDefault(nestedKey, ""));
                                if(!"".equals(_keyValue) && _innerkey.equals(_keyValue)) {
                                    Map<String, HighlightField> _highMap = _innerHit.getHighlightFields();
                                    HighlightField hlObj = _highMap.get(nestedName+"."+_fieldName);
                                    if(hlObj !=null) {
                                        Text[] objss =hlObj.getFragments();
                                        if(objss!=null && objss.length>0) {
                                            _value = objss[0].toString();
                                            break;
                                        }
                                    }
                                }
                            }

                        }else {
                            _value = String.valueOf(_data.getOrDefault(_fieldName, ""));

                        }
                        if("".equals(_value)) {
                            _value = String.valueOf(_data.getOrDefault(defaultField, ""));
                        }
                        _retData.put(fieldValueName,_value );
                    }



                    _retList.add(_retData);
                }
            }else {
                if(innerHits!=null) {
                    for(SearchHit _innerHit : innerHits) {
                        Map<String, Object> _innermap = _innerHit.getSourceAsMap();
                        String _innerkey = String.valueOf(_innermap.getOrDefault(nestedKey, ""));
                        for(Map<String, Object> _data : _nestList){
                            Map<String, String> _retData = new HashMap<String, String>();
                            String _keyValue =String.valueOf(_data.getOrDefault(nestedKey, ""));

                            if(!"".equals(_keyValue) && _innerkey.equals(_keyValue)) {
                                String _value = "";
                                for(String _fieldName : filedList) {
                                    String aliasInfos[]=ProUtils.split(_fieldName, ":");
                                    String defaultField = "";
                                    String fieldValueName = "";

                                    if(aliasInfos.length>2) {
                                        _fieldName = aliasInfos[0];
                                        defaultField = aliasInfos[1];
                                        fieldValueName = aliasInfos[2];
                                    }else if(aliasInfos.length>1) {
                                        _fieldName = aliasInfos[0];
                                        defaultField = aliasInfos[1];
                                        fieldValueName = _fieldName;
                                    }else {
                                        _fieldName = aliasInfos[0];
                                        defaultField = _fieldName;
                                        fieldValueName = defaultField;
                                    }
                                    _value = String.valueOf(_data.getOrDefault(defaultField, ""));

                                    Map<String, HighlightField> _highMap = _innerHit.getHighlightFields();

                                    HighlightField hlObj = _highMap.get(nestedName+"."+_fieldName);

                                    if(hlObj !=null) {
                                        Text[] objss =hlObj.getFragments();
                                        if(objss!=null && objss.length>0) {
                                            _value = objss[0].toString();
                                        }
                                    }


                                    _retData.put(fieldValueName,_value );
                                }
                                _retList.add(_retData);
                            }
                        }
                    }
                }
            }
            return _retList;
        }
        return _retList;
    }



    /**
     * 필드 Nested Data 를 가져온다.
     * @param hit
     * @param fieldName
     * @param def
     * @param isHighlight
     * @return
     */

    public Object getNestedFieldData( SearchHit hit, String fieldName, Object def , boolean isHighlight) {
        Map<String, Object> map = hit.getSourceAsMap();
        Object _ret = "";

        if(isHighlight) {
            Map<String, HighlightField> _highMap = hit.getHighlightFields();
            HighlightField hlObj = _highMap.get(fieldName);

            if(hlObj !=null) {
                Text[] objss =hlObj.getFragments();
                if(objss!=null && objss.length>0) {
                    String fieldInfo[]=ProUtils.split(fieldName,".");
                    Object _nestObj = map.getOrDefault(fieldInfo[0],def);
                    List<String> _retList = new ArrayList<String>();
                    if(_nestObj instanceof List<?>){
                        List<Map<String, Object>> _nestList = (List<Map<String, Object>>)_nestObj;

                        for(Map<String, Object> _data : _nestList){
                            String orgData = String.valueOf(_data.getOrDefault(fieldInfo[1],""));
                            boolean isCheck = true;
                            for(Text _hightData : objss){
                                String _hightText = _hightData.toString();
                                _hightText =  ProUtils.getHighlightTag(_hightText,"","").trim();
                                if(_hightText.equals(orgData)){
                                    _retList.add(_hightData.toString());
                                    isCheck = false;
                                    break;
                                }
                            }
                            if(isCheck){
                                _retList.add(orgData);
                            }
                        }
                        return _retList;
                    }else{
                        _ret = map.getOrDefault(fieldInfo[0],def);
                    }
                }
            }else {
                if(fieldName.indexOf(".")>-1){
                    String fieldInfo[]=ProUtils.split(fieldName,".");
                    Object _nestObj = map.getOrDefault(fieldInfo[0],def);
                    if(_nestObj instanceof List<?>){
                        List<Map<String, Object>> _nestList = (List<Map<String, Object>>)_nestObj;
                        List<String> _retList = new ArrayList<String>();
                        for(Map<String, Object> _data : _nestList){
                            _retList.add(String.valueOf(_data.getOrDefault(fieldInfo[1],"")));
                        }
                        return _retList;
                    }else{
                        _ret = map.getOrDefault(fieldInfo[0],def);
                    }
                }else{
                    _ret = map.getOrDefault(fieldName,def);
                }
            }

        }else {
            if(fieldName.indexOf(".")>-1){
                String fieldInfo[]=ProUtils.split(fieldName,".");
                Object _nestObj = map.getOrDefault(fieldInfo[0],def);
                if(_nestObj instanceof List<?>){
                    List<Map<String, Object>> _nestList = (List<Map<String, Object>>)_nestObj;
                    List<String> _retList = new ArrayList<String>();
                    for(Map<String, Object> _data : _nestList){
                        _retList.add(String.valueOf(_data.getOrDefault(fieldInfo[1],"")));
                    }
                    return _retList;
                }else{
                    _ret = map.getOrDefault(fieldInfo[0],def);
                }
            }else{
                _ret = map.getOrDefault(fieldName,def);
            }
        }
        return _ret;
    }



    /**
     * multiSearchRequest를 초기화 한다.
     * @return
     */
    public synchronized void clear() {
        try {
            this.debugMsgBuffer = new StringBuffer();
            this.errorMsgBuffer = new StringBuffer();
            this.warnMsgBuffer = new StringBuffer();
            this.multiSearchRequest = new MultiSearchRequest();
        } catch ( Exception e ) {
            e.printStackTrace();
            appendERROR(e.getMessage());
        }
    }



    public String callSetQueryLog(String query, String index, long took,long total) {

        try {
            query = URLEncoder.encode(query, "UTF-8");
        } catch(Exception e) {
//        	logger.error(e.getMessage());
        }

        String url = "http://" + ES_SERVERS + "/_pro10-querylog";

        String params = "?query=" + query + "&service=" + index + "&cnt=" + total + "&took=" + took ;

        return callPluginAPI(url + params, "");
    }


    public String callSuggestQuery(String query) {

        try {
            query = URLEncoder.encode(query, "UTF-8");
        } catch(Exception e) {
//        	logger.error(e.getMessage());
        }

        String url = "http://" + ES_SERVERS + "/_pro10-speller";

        String params = "?query=" + query ;

        String retString = "";
        if ( !"".equals(query) ) {
            retString = callPluginAPI(url + params, "");
        }

        return retString;
    }

	//내가 클릭한문서 입력
     public String addClickQuery(String query, String userid, String title, String curl) {
		//입력
		//<ES서버URL>/_pro10-clicklog?service=@ALL&query=test&addinfo=test123&cid=1&csubject=title&curl=http://aaa.co.kr&cetc=&method=
        try {
            query = URLEncoder.encode(query, "UTF-8");
        } catch(Exception e) {
//        	logger.error(e.getMessage());
        }

        String url = "http://" + ES_SERVERS + "/_pro10-clicklog";

		String params = "?service=@ALL&query=" + query + "&addinfo=" + userid + "&cid=1&csubject=" + title + "&curl=" + curl + "&cetc=&method=";

        String retString = "";
        if ( !"".equals(query) ) {
            retString = callPluginAPI(url + params, "");
        }

        return retString;
    }


	//내가 클릭한문서 삭제
     public String deleteClickQuery(String query, String userid) {
		//삭제
		//<ES서버 URL>/_pro10-clicklog?method=d&addinfo=test123&query=20210727113522287
        try {
            query = URLEncoder.encode(query, "UTF-8");
        } catch(Exception e) {
//        	logger.error(e.getMessage());
        }

        String url = "http://" + ES_SERVERS + "/_pro10-clicklog";

		String params = "?query=" + query + "&addinfo=" + userid + "&method=d";

        String retString = "";
        if ( !"".equals(userid) ) {
            retString = callPluginAPI(url + params, "");
        }

        return retString;
    }


	//내가 클릭한문서 조회
	public String callClickQuery(String userid) {
		
		//조회
		//<ES서버 URL>/_pro10-clicklog?addinfo=test123&method=s        
		try {
            query = URLEncoder.encode(query, "UTF-8");
        } catch(Exception e) {
//        	logger.error(e.getMessage());
        }

        String url = "http://" + ES_SERVERS + "/_pro10-clicklog";

		String params = "?addinfo=" + userid + "&method=s";

        String retString = "";
        if ( !"".equals(userid) ) {
            retString = callPluginAPI(url + params, "");
        }

        return retString;
    }


    public String callPluginAPI(String url, String params) {

        StringBuffer receiveMsg = new StringBuffer();
        HttpURLConnection uc = null;
        try {
            URL servletUrl = new URL(url);
            uc = (HttpURLConnection) servletUrl.openConnection();
            uc.setRequestProperty("Content-type", "application/x-www-form-urlencoded");
            uc.setRequestMethod("POST");
            uc.setDoOutput(true);
            uc.setDoInput(true);
            uc.setUseCaches(false);
            uc.setDefaultUseCaches(false);
            DataOutputStream dos = new DataOutputStream (uc.getOutputStream());
            dos.write(params.getBytes());
            dos.flush();
            dos.close();

            int errorCode = 0;

            if (uc.getResponseCode() == HttpURLConnection.HTTP_OK) {
                String currLine = "";
                // UTF-8. ..
                BufferedReader in = new BufferedReader(new InputStreamReader(uc.getInputStream(), "UTF-8"));
                while ((currLine = in.readLine()) != null) {
                    receiveMsg.append(currLine).append("\r\n");
                }
                in.close();
            } else {
                errorCode = uc.getResponseCode();
                return receiveMsg.toString();
            }
        } catch(Exception ex) {
//        	logger.error(ex);
        } finally {
            uc.disconnect();
        }
        return receiveMsg.toString();
    }

    public void setNestSearchField(String index, String value) {
        searchMap.put(index + "@" + "NEST_SEARCH" , value );
    }

    public void addIndex(String index) {
        if ( !indexList.contains(index) )
          indexList.add(index);
    }

    public void setAlias(String index, String value) {
		if ( !"".equals(value.trim()) ) {		
			searchMap.put(index + "@" + "ALIAS" , value );
		}
    }

    public void setSearchField(String index, String value) {
		if ( !"".equals(value.trim()) ) {
			searchMap.put(index + "@" + "SEARCH" , value );
		}
    }

    public void setExcludeField(String index, String value) {
		if ( !"".equals(value.trim()) ) {
			searchMap.put(index + "@" + "EXCLUDE" , value );
		}	
    }
    public void setIncludeField(String index, String value) {
		if ( !"".equals(value.trim()) ) {
			searchMap.put(index + "@" + "INCLUDE" , value );
		}	
    }
    public void setHighlightField(String index, String value) {
		if ( !"".equals(value.trim()) ) {
			searchMap.put(index + "@" + "HIGHLIGHT" , value );
		}
    }

    public void setFilterQuery(String index, String value) {
		if ( !"".equals(value.trim()) ) {
			searchMap.put(index + "@" + "FILTER_QUERY" , value );
		}
    }

    public void setQueryString(String index, String value) {
		if ( !"".equals(value.trim()) ) {
			searchMap.put(index + "@" + "QUERY_STRING" , value );
		}
    }

    public void setDateRange(String index, String value) {
		if ( !"".equals(value.trim()) ) {
			searchMap.put(index + "@" + "DATE_RANGE" , value );
		}
    }

    public void setValueRange(String index, String value) {
		if ( !"".equals(value.trim()) ) {
			searchMap.put(index + "@" + "VALUE_RANGE" , value );
		}
    }
    public void setPage(String index, String value) {
		if ( !"".equals(value.trim()) ) {
			searchMap.put(index + "@" + "PAGE" , value );
		}
    }

    public void setAggs(String index, String value) {
		if ( !"".equals(value.trim()) ) {
			searchMap.put(index + "@" + "AGGREGATION" , value );
		}
    }

    public void setSortField(String index, String value) {
		if ( !"".equals(value.trim()) ) {
			searchMap.put(index + "@" + "SORT" , value );
		}
    }

	public void setNotQueryString(String index, String value) {
		if ( !"".equals(value.trim()) ) {
			searchMap.put(index + "@" + "NOT_QUERY" , value );
		}
    }

    public void setNestExcludeField(String index, String value) {
		if ( !"".equals(value.trim()) ) {
			searchMap.put(index + "@" + "NEST_EXCLUDE" , value );
		}
    }
    public void setNestIncludeField(String index, String value) {
		if ( !"".equals(value.trim()) ) {
			searchMap.put(index + "@" + "NEST_INCLUDE" , value );
		}
    }
    public void setNestHighlightField(String index, String value) {
		if ( !"".equals(value.trim()) ) {
			searchMap.put(index + "@" + "NEST_HIGHLIGHT" , value );
		}
    } 
	
    public void setIndexViewName(String index, String value) {
		if ( !"".equals(value.trim()) ) {
			searchMap.put(index + "@" + "INDEX_VIEW_NAME" , value );
		}
    } 
 
}
 
%>
