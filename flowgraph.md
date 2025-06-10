# History Quiz App - Complete System Flowgraph

This document contains the complete system flowgraph for whitebox testing of the History Quiz App application.

```mermaid
%%{init: { 'flowchart': { 'curve': 'basis', 'nodeSpacing': 50, 'rankSpacing': 50, 'width': 2000 } } }%%
flowchart LR
    %% Define styles for better readability
    classDef process fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef decision fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef start fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    classDef endnode fill:#fbe9e7,stroke:#bf360c,stroke-width:2px
    classDef service fill:#f3e5f5,stroke:#4a148c,stroke-width:2px

    %% Services Initialization
    subgraph Services ["Core Services"]
        direction LR
        PermissionSvc[Permission Service]:::service
        AuthSvc[Auth Service]:::service
        NotifSvc[Notification Service]:::service
        DBSvc[Database Helper]:::service
        ImageSvc[Image Service]:::service
        EncryptSvc[Encryption Service]:::service
    end

    %% Application Initialization
    subgraph Init ["System Initialization"]
        direction LR
        Start[/"Start Application"/]:::start --> InitApp[Initialize Flutter Binding]
        InitApp --> InitTheme[Initialize Dynamic Theme]
        InitTheme --> CheckPlatform{Platform Check}:::decision
        
        CheckPlatform -->|Android| PermissionSvc
        CheckPlatform -->|iOS| AuthSvc
        
        PermissionSvc --> StorageCheck{Storage<br>Permission}:::decision
        StorageCheck -->|Denied| RequestStorage[Request Storage]
        StorageCheck -->|Granted| ExternalCheck{External<br>Storage}:::decision
        RequestStorage --> ExternalCheck
        
        ExternalCheck -->|API >= 30| RequestManage[Request Manage]
        ExternalCheck -->|API < 30| NotifCheck{Notification<br>Permission}:::decision
        RequestManage --> NotifCheck
        NotifCheck -->|Denied| RequestNotif[Request Notification]
        NotifCheck -->|Granted| AuthSvc
        RequestNotif --> AuthSvc
    end

    %% Authentication Flow
    subgraph Auth ["Authentication"]
        direction LR
        AuthSvc --> LoadSession[Load Session]
        LoadSession --> ValidateSession{Valid<br>Session?}:::decision
        ValidateSession -->|Yes| SetLoggedIn[Set Logged In]
        ValidateSession -->|No| ShowLogin[Show Login Screen]
        
        ShowLogin --> LoginChoice{User Choice}:::decision
        LoginChoice -->|Login| LoginForm[Login Form]
        LoginChoice -->|Register| RegisterForm[Register Form]
        
        LoginForm --> ValidateLogin{Validate}:::decision
        RegisterForm --> ValidateReg{Validate}:::decision
        
        ValidateLogin -->|Success| CreateSession[Create Session]
        ValidateReg -->|Success| CreateUser[Create User]
        CreateUser --> CreateSession
        
        ValidateLogin -->|Failed| ShowLoginError[Show Error]
        ValidateReg -->|Failed| ShowRegError[Show Error]
        
        CreateSession --> InitNotif[Initialize Notifications]
        SetLoggedIn --> InitNotif
    end

    %% Main Navigation
    subgraph Nav ["Main Navigation"]
        direction LR
        InitNotif --> NotifSvc
        NotifSvc --> HomeScreen[Home Screen]
        
        HomeScreen --> MainActions{User Action}:::decision
        MainActions -->|Start Game| GameScreen[Game Screen]
        MainActions -->|Profile| ProfileScreen[Profile Screen]
        MainActions -->|Support| SupportScreen[Support Screen]
        MainActions -->|Feedback| FeedbackScreen[Feedback Screen]
        MainActions -->|Notifications| NotifScreen[Notification Test Screen]
    end

    %% Game Flow
    subgraph Game ["Game System"]
        direction LR
        GameScreen --> InitGame[Initialize Game Controller]
        InitGame --> FetchQuestion[Fetch Question]
        FetchQuestion --> CheckBuffer{In Buffer?}:::decision
        
        CheckBuffer -->|Yes| GetBuffered[Get from Buffer]
        CheckBuffer -->|No| CheckDiff{Difficulty}:::decision
        
        CheckDiff -->|Hard| LoadPredefined[Load Predefined]
        CheckDiff -->|Easy/Medium| FetchAPI[Fetch from API]
        
        FetchAPI --> ValidateAPI{API Success?}:::decision
        ValidateAPI -->|Yes| ParseQuestions[Parse Questions]
        ValidateAPI -->|No| RetryAPI{Retry?}:::decision
        RetryAPI -->|Yes| FetchAPI
        RetryAPI -->|No| CreateDummy[Create Dummy]
        
        ParseQuestions --> FilterQuestions[Filter Used Questions]
        LoadPredefined --> FilterQuestions
        FilterQuestions --> AddToBuffer[Add to Buffer]
        CreateDummy --> ShowQuestion[Display Question]
        AddToBuffer --> ShowQuestion
        GetBuffered --> ShowQuestion
        
        ShowQuestion --> WaitAnswer{User Answer}:::decision
        WaitAnswer -->|Correct| UpdateScore[Update Score]
        WaitAnswer -->|Wrong| NoUpdate[No Update]
        
        UpdateScore & NoUpdate --> CheckEnd{Game End?}:::decision
        CheckEnd -->|No| FetchQuestion
        CheckEnd -->|Yes| SaveResult[Save Result]
        
        SaveResult --> DBSvc
        DBSvc --> ShowResult[Show Result Screen]:::endnode
    end

    %% Profile System
    subgraph Profile ["Profile System"]
        direction LR
        ProfileScreen --> LoadProfile[Load Profile]
        LoadProfile --> DBSvc
        DBSvc --> CheckData{Data Exists?}:::decision
        CheckData -->|Yes| ShowStats[Show Statistics]
        CheckData -->|No| CreateProfile[Create Profile]
        CreateProfile --> ShowStats
        
        ShowStats --> LoadHistory[Load Game History]
        LoadHistory --> DBSvc
        DBSvc --> DisplayHistory[Display History]:::endnode
    end

    %% Support System
    subgraph Support ["Support System"]
        direction LR
        SupportScreen --> LoadFAQ[Load FAQ]
        LoadFAQ --> ShowCategories[Show Categories]
        ShowCategories --> UserSelect{Selection}:::decision
        UserSelect -->|View FAQ| ShowFAQ[Show FAQ Content]
        UserSelect -->|Contact| ContactForm[Show Contact Form]
        ContactForm --> ValidateForm{Valid Form?}:::decision
        ValidateForm -->|Yes| SendRequest[Send Request]:::endnode
        ValidateForm -->|No| ShowError[Show Error]
    end

    %% Feedback System
    subgraph Feedback ["Feedback System"]
        direction LR
        FeedbackScreen --> ShowForm[Show Feedback Form]
        ShowForm --> ValidateInput{Valid Input?}:::decision
        ValidateInput -->|Yes| ProcessFeedback[Process Feedback]
        ValidateInput -->|No| ShowInputError[Show Error]
        ProcessFeedback --> SaveFeedback[Save Feedback]
        SaveFeedback --> DBSvc
        DBSvc --> ShowThanks[Show Thanks]:::endnode
    end

    %% Connect main subgraphs
    Start --> Services
    Init --> Auth
    Auth --> Nav

    %% Apply styles
    class Start start
    class ShowResult,DisplayHistory,SendRequest,ShowThanks endnode
    class CheckPlatform,StorageCheck,ExternalCheck,NotifCheck,ValidateSession,LoginChoice,ValidateLogin,ValidateReg,MainActions,CheckBuffer,CheckDiff,ValidateAPI,RetryAPI,WaitAnswer,CheckEnd,CheckData,UserSelect,ValidateForm,ValidateInput decision
    class PermissionSvc,AuthSvc,NotifSvc,DBSvc,ImageSvc,EncryptSvc service

    %% Layout settings
    linkStyle default stroke-width:5px