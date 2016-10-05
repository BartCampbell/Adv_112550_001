CREATE TABLE [stage].[ChaseList]
(
[ChaseID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MemberID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProviderID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProviderAddress] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProviderCity] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProviderState] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProviderZip] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProviderPhone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProviderFax] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Employee_YN] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Provider_PK] [int] NULL,
[ProviderMaster_PK] [int] NULL,
[ProviderOffice_PK] [int] NULL,
[ProviderMisMatch] [bit] NULL,
[AddNewAddress] [bit] NULL,
[Old_Provider_PK] [int] NULL,
[Old_ProviderMaster_PK] [int] NULL,
[Old_ProviderOffice_PK] [int] NULL,
[Updated] [bit] NULL
) ON [PRIMARY]
GO
