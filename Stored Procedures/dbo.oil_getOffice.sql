SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Sajid Ali
-- Create date: Mar-12-2014
-- Description:	RA Coder will use this sp to pull list of providers in a project
-- =============================================
--	oil_getOffice 0,1,25,'','FU','DESC',0,0,0,1,1
CREATE PROCEDURE [dbo].[oil_getOffice]
	@Projects varchar(100),
	@ProjectGroup varchar(10),
	@Page int,
	@PageSize int,
	@Alpha Varchar(2),
	@Sort Varchar(150),
	@Order Varchar(4),
	@Provider BigInt,
	@filter_type int,
	@filter_type_sub int,
	@user int
AS
BEGIN
	-- PROJECT SELECTION
	CREATE TABLE #tmpProject (Project_PK INT)
	IF @Projects='0'
	BEGIN
		IF Exists (SELECT * FROM tblUser WHERE IsAdmin=1 AND User_PK=@User)	--For Admins
			INSERT INTO #tmpProject(Project_PK)
			SELECT DISTINCT Project_PK FROM tblProject P WHERE P.IsRetrospective=1 AND (@ProjectGroup=0 OR ProjectGroup_PK=@ProjectGroup)
		ELSE
			INSERT INTO #tmpProject(Project_PK)
			SELECT DISTINCT P.Project_PK FROM tblProject P LEFT JOIN tblUserProject UP ON UP.Project_PK = P.Project_PK
			WHERE P.IsRetrospective=1 AND UP.User_PK=@User AND (@ProjectGroup=0 OR ProjectGroup_PK=@ProjectGroup)
	END
	ELSE
		EXEC ('INSERT INTO #tmpProject(Project_PK) SELECT Project_PK FROM tblProject WHERE Project_PK IN ('+@Projects+') AND ('+@ProjectGroup+'=0 OR ProjectGroup_PK='+@ProjectGroup+')');	
	-- PROJECT SELECTION
		
	DECLARE @OFFICE AS BIGINT
	if (@Provider=0)
		SET @OFFICE = 0;
	else
		SELECT @OFFICE = ProviderOffice_PK FROM tblProvider WITH (NOLOCK) WHERE Provider_PK=@Provider;

	With tbl AS(
	SELECT ROW_NUMBER() OVER(
		ORDER BY 
			CASE WHEN @Order='ASC'  THEN CASE @SORT WHEN 'AD' THEN PO.Address WHEN 'CT' THEN ZC.City WHEN 'CN' THEN ZC.County WHEN 'ST' THEN ZC.State WHEN 'ZC' THEN ZC.Zipcode WHEN 'CP' THEN PO.ContactPerson WHEN 'CNU' THEN PO.ContactNumber WHEN 'FN' THEN PO.FaxNumber ELSE NULL END END ASC,
			CASE WHEN @Order='DESC' THEN CASE @SORT WHEN 'AD' THEN PO.Address WHEN 'CT' THEN ZC.City WHEN 'CN' THEN ZC.County WHEN 'ST' THEN ZC.State WHEN 'ZC' THEN ZC.Zipcode WHEN 'CP' THEN PO.ContactPerson WHEN 'CNU' THEN PO.ContactNumber WHEN 'FN' THEN PO.FaxNumber ELSE NULL END END DESC,
			CASE WHEN @Order='ASC'  THEN CASE @SORT WHEN 'CH' THEN SUM(cPO.Charts) WHEN 'IS' THEN MIN(POS.OfficeIssueStatus) WHEN 'PRV' THEN SUM(cPO.Providers) WHEN 'FU' THEN CASE WHEN SUM(cPO.extracted_count)+SUM(cPO.cna_count)>=SUM(cPO.Charts) THEN 9999 ELSE MIN(CASE WHEN cPO.extracted_count+cPO.cna_count>=cPO.Charts THEN 9999 ELSE DATEDIFF(day,GetDate(),follow_up) END) END ELSE NULL END END ASC,
			CASE WHEN @Order='DESC' THEN CASE @SORT WHEN 'CH' THEN SUM(cPO.Charts) WHEN 'IS' THEN MIN(POS.OfficeIssueStatus) WHEN 'PRV' THEN SUM(cPO.Providers) WHEN 'FU' THEN CASE WHEN SUM(cPO.extracted_count)+SUM(cPO.cna_count)>=SUM(cPO.Charts) THEN 9999 ELSE MIN(CASE WHEN cPO.extracted_count+cPO.cna_count>=cPO.Charts THEN 9999 ELSE DATEDIFF(day,GetDate(),follow_up) END) END ELSE NULL END END DESC 
		) AS RowNumber
			,MAX(cPO.Project_PK) Project_PK,cPO.ProviderOffice_PK,PO.Address,ZC.City,ZC.County,ZC.State,PO.ZipCode_PK,ZC.Zipcode,PO.ContactPerson,PO.ContactNumber,PO.FaxNumber,PO.Email_Address,Isnull(PO.EMR_Type_PK,0) EMR_Type_PK
			,SUM(cPO.Providers) Providers
			,Sum(cPO.Charts-cPO.extracted_count-cPO.cna_count) Charts
			,MIN(CASE WHEN cPO.extracted_count+cPO.cna_count>=cPO.Charts THEN 9999 ELSE DATEDIFF(day,GetDate(),follow_up) END) followup_days
			,MIN(schedule_type) schedule_type,SUM(cPO.extracted_count) extracted,SUM(cPO.coded_count) coded,SUM(cPO.cna_count) cna
			,MIN(PO.ProviderOfficeBucket_PK) OfficeStatus
			,MIN(POS.OfficeIssueStatus) OfficeIssueStatus
		FROM tblProviderOffice PO WITH (NOLOCK) 
			INNER JOIN cacheProviderOffice cPO WITH (NOLOCK) ON cPO.ProviderOffice_PK = PO.ProviderOffice_PK
			INNER JOIN #tmpProject P ON P.Project_PK = cPO.Project_PK
			Outer APPLY (SELECT TOP 1 * FROM tblProviderOfficeStatus WHERE ProviderOffice_PK = cPO.ProviderOffice_PK) POS
			LEFT JOIN tblZipcode ZC WITH (NOLOCK) ON ZC.ZipCode_PK = PO.ZipCode_PK	
		WHERE IsNull(PO.Address,0) Like @Alpha+'%'
			AND (@OFFICE=0 OR PO.ProviderOffice_PK=@OFFICE)
			AND (@OFFICE<>0 OR POS.OfficeIssueStatus IS NOT NULL)
			AND (@OFFICE<>0 OR (@filter_type=0 OR POS.OfficeIssueStatus=@filter_type))
		GROUP BY cPO.ProviderOffice_PK,PO.Address,ZC.City,ZC.County,ZC.State,PO.ZipCode_PK,ZC.Zipcode,PO.ContactPerson,PO.ContactNumber,PO.FaxNumber,PO.Email_Address,Isnull(PO.EMR_Type_PK,0)
	)
	
	SELECT * FROM tbl WHERE RowNumber>@PageSize*(@Page-1) AND RowNumber<=@PageSize*@Page ORDER BY RowNumber
	
	SELECT UPPER(LEFT(PO.Address,1)) alpha1, UPPER(RIGHT(LEFT(PO.Address,2),1)) alpha2,Count(DISTINCT cPO.ProviderOffice_PK) records
		FROM tblProviderOffice PO WITH (NOLOCK) 
			INNER JOIN cacheProviderOffice cPO WITH (NOLOCK) ON cPO.ProviderOffice_PK = PO.ProviderOffice_PK
			INNER JOIN #tmpProject P ON P.Project_PK = cPO.Project_PK
			Outer APPLY (SELECT TOP 1 * FROM tblProviderOfficeStatus WHERE ProviderOffice_PK = cPO.ProviderOffice_PK) POS
			LEFT JOIN tblZipcode ZC WITH (NOLOCK) ON ZC.ZipCode_PK = PO.ZipCode_PK	
		WHERE (@OFFICE=0 OR PO.ProviderOffice_PK=@OFFICE)
			AND (@OFFICE<>0 OR POS.OfficeIssueStatus IS NOT NULL)
			AND (@OFFICE<>0 OR (@filter_type=0 OR POS.OfficeIssueStatus=@filter_type))
		GROUP BY LEFT(PO.Address,1), RIGHT(LEFT(PO.Address,2),1)			
		ORDER BY alpha1, alpha2;
END
GO