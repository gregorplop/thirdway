#tag Window
Begin Window MainWindow
   BackColor       =   &cFFFFFF00
   Backdrop        =   0
   CloseButton     =   True
   Compatibility   =   ""
   Composite       =   False
   Frame           =   0
   FullScreen      =   False
   FullScreenButton=   False
   HasBackColor    =   False
   Height          =   694
   ImplicitInstance=   True
   LiveResize      =   True
   MacProcID       =   0
   MaxHeight       =   32000
   MaximizeButton  =   True
   MaxWidth        =   32000
   MenuBar         =   0
   MenuBarVisible  =   True
   MinHeight       =   600
   MinimizeButton  =   True
   MinWidth        =   900
   Placement       =   0
   Resizeable      =   True
   Title           =   "thirdway playground"
   Visible         =   True
   Width           =   910
   Begin PagePanel MainPanel
      AutoDeactivate  =   True
      Enabled         =   True
      Height          =   694
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Left            =   0
      LockBottom      =   True
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   False
      LockTop         =   True
      PanelCount      =   4
      Panels          =   ""
      Scope           =   0
      TabIndex        =   0
      TabPanelIndex   =   0
      Top             =   0
      Transparent     =   False
      Value           =   3
      Visible         =   True
      Width           =   435
      Begin PushButton ClientModeBtn
         AutoDeactivate  =   True
         Bold            =   False
         ButtonStyle     =   "0"
         Cancel          =   False
         Caption         =   "Client"
         Default         =   False
         Enabled         =   True
         Height          =   76
         HelpTag         =   ""
         Index           =   -2147483648
         InitialParent   =   "MainPanel"
         Italic          =   False
         Left            =   20
         LockBottom      =   False
         LockedInPosition=   False
         LockLeft        =   True
         LockRight       =   False
         LockTop         =   True
         Scope           =   0
         TabIndex        =   0
         TabPanelIndex   =   1
         TabStop         =   True
         TextFont        =   "System"
         TextSize        =   16.0
         TextUnit        =   0
         Top             =   299
         Transparent     =   False
         Underline       =   False
         Visible         =   True
         Width           =   395
      End
      Begin PushButton ControllerModeBtn
         AutoDeactivate  =   True
         Bold            =   False
         ButtonStyle     =   "0"
         Cancel          =   False
         Caption         =   "Controller"
         Default         =   False
         Enabled         =   True
         Height          =   76
         HelpTag         =   ""
         Index           =   -2147483648
         InitialParent   =   "MainPanel"
         Italic          =   False
         Left            =   20
         LockBottom      =   False
         LockedInPosition=   False
         LockLeft        =   True
         LockRight       =   False
         LockTop         =   True
         Scope           =   0
         TabIndex        =   1
         TabPanelIndex   =   1
         TabStop         =   True
         TextFont        =   "System"
         TextSize        =   16.0
         TextUnit        =   0
         Top             =   387
         Transparent     =   False
         Underline       =   False
         Visible         =   True
         Width           =   395
      End
      Begin TextField hostField
         AcceptTabs      =   False
         Alignment       =   2
         AutoDeactivate  =   True
         AutomaticallyCheckSpelling=   False
         BackColor       =   &cFFFFFF00
         Bold            =   False
         Border          =   True
         CueText         =   "host"
         DataField       =   ""
         DataSource      =   ""
         Enabled         =   True
         Format          =   ""
         Height          =   30
         HelpTag         =   "host"
         Index           =   -2147483648
         InitialParent   =   "MainPanel"
         Italic          =   False
         Left            =   20
         LimitText       =   0
         LockBottom      =   False
         LockedInPosition=   False
         LockLeft        =   True
         LockRight       =   False
         LockTop         =   True
         Mask            =   ""
         Password        =   False
         ReadOnly        =   False
         Scope           =   0
         TabIndex        =   0
         TabPanelIndex   =   1
         TabStop         =   True
         Text            =   ""
         TextColor       =   &c00000000
         TextFont        =   "System"
         TextSize        =   16.0
         TextUnit        =   0
         Top             =   20
         Transparent     =   False
         Underline       =   False
         UseFocusRing    =   True
         Visible         =   True
         Width           =   120
      End
      Begin TextField portField
         AcceptTabs      =   False
         Alignment       =   2
         AutoDeactivate  =   True
         AutomaticallyCheckSpelling=   False
         BackColor       =   &cFFFFFF00
         Bold            =   False
         Border          =   True
         CueText         =   "port"
         DataField       =   ""
         DataSource      =   ""
         Enabled         =   True
         Format          =   ""
         Height          =   30
         HelpTag         =   "port"
         Index           =   -2147483648
         InitialParent   =   "MainPanel"
         Italic          =   False
         Left            =   20
         LimitText       =   0
         LockBottom      =   False
         LockedInPosition=   False
         LockLeft        =   True
         LockRight       =   False
         LockTop         =   True
         Mask            =   ""
         Password        =   False
         ReadOnly        =   False
         Scope           =   0
         TabIndex        =   1
         TabPanelIndex   =   1
         TabStop         =   True
         Text            =   ""
         TextColor       =   &c00000000
         TextFont        =   "System"
         TextSize        =   16.0
         TextUnit        =   0
         Top             =   62
         Transparent     =   False
         Underline       =   False
         UseFocusRing    =   True
         Visible         =   True
         Width           =   120
      End
      Begin TextField usernameField
         AcceptTabs      =   False
         Alignment       =   2
         AutoDeactivate  =   True
         AutomaticallyCheckSpelling=   False
         BackColor       =   &cFFFFFF00
         Bold            =   False
         Border          =   True
         CueText         =   "user name"
         DataField       =   ""
         DataSource      =   ""
         Enabled         =   True
         Format          =   ""
         Height          =   30
         HelpTag         =   "user name"
         Index           =   -2147483648
         InitialParent   =   "MainPanel"
         Italic          =   False
         Left            =   20
         LimitText       =   0
         LockBottom      =   False
         LockedInPosition=   False
         LockLeft        =   True
         LockRight       =   False
         LockTop         =   True
         Mask            =   ""
         Password        =   False
         ReadOnly        =   False
         Scope           =   0
         TabIndex        =   2
         TabPanelIndex   =   1
         TabStop         =   True
         Text            =   ""
         TextColor       =   &c00000000
         TextFont        =   "System"
         TextSize        =   16.0
         TextUnit        =   0
         Top             =   146
         Transparent     =   False
         Underline       =   False
         UseFocusRing    =   True
         Visible         =   True
         Width           =   120
      End
      Begin TextField passwordField
         AcceptTabs      =   False
         Alignment       =   2
         AutoDeactivate  =   True
         AutomaticallyCheckSpelling=   False
         BackColor       =   &cFFFFFF00
         Bold            =   False
         Border          =   True
         CueText         =   "password"
         DataField       =   ""
         DataSource      =   ""
         Enabled         =   True
         Format          =   ""
         Height          =   30
         HelpTag         =   "password"
         Index           =   -2147483648
         InitialParent   =   "MainPanel"
         Italic          =   False
         Left            =   20
         LimitText       =   0
         LockBottom      =   False
         LockedInPosition=   False
         LockLeft        =   True
         LockRight       =   False
         LockTop         =   True
         Mask            =   ""
         Password        =   True
         ReadOnly        =   False
         Scope           =   0
         TabIndex        =   3
         TabPanelIndex   =   1
         TabStop         =   True
         Text            =   ""
         TextColor       =   &c00000000
         TextFont        =   "System"
         TextSize        =   16.0
         TextUnit        =   0
         Top             =   188
         Transparent     =   False
         Underline       =   False
         UseFocusRing    =   True
         Visible         =   True
         Width           =   120
      End
      Begin PushButton ConnectBtn
         AutoDeactivate  =   True
         Bold            =   False
         ButtonStyle     =   "0"
         Cancel          =   False
         Caption         =   "Connect"
         Default         =   False
         Enabled         =   True
         Height          =   30
         HelpTag         =   "Connect to posgreSQL server"
         Index           =   -2147483648
         InitialParent   =   "MainPanel"
         Italic          =   False
         Left            =   211
         LockBottom      =   False
         LockedInPosition=   False
         LockLeft        =   True
         LockRight       =   False
         LockTop         =   True
         Scope           =   0
         TabIndex        =   5
         TabPanelIndex   =   1
         TabStop         =   True
         TextFont        =   "System"
         TextSize        =   16.0
         TextUnit        =   0
         Top             =   145
         Transparent     =   False
         Underline       =   False
         Visible         =   True
         Width           =   144
      End
      Begin TextField databasenameField
         AcceptTabs      =   False
         Alignment       =   2
         AutoDeactivate  =   True
         AutomaticallyCheckSpelling=   False
         BackColor       =   &cFFFFFF00
         Bold            =   False
         Border          =   True
         CueText         =   "database"
         DataField       =   ""
         DataSource      =   ""
         Enabled         =   True
         Format          =   ""
         Height          =   30
         HelpTag         =   "database"
         Index           =   -2147483648
         InitialParent   =   "MainPanel"
         Italic          =   False
         Left            =   20
         LimitText       =   0
         LockBottom      =   False
         LockedInPosition=   False
         LockLeft        =   True
         LockRight       =   False
         LockTop         =   True
         Mask            =   ""
         Password        =   False
         ReadOnly        =   False
         Scope           =   0
         TabIndex        =   7
         TabPanelIndex   =   1
         TabStop         =   True
         Text            =   ""
         TextColor       =   &c00000000
         TextFont        =   "System"
         TextSize        =   16.0
         TextUnit        =   0
         Top             =   104
         Transparent     =   False
         Underline       =   False
         UseFocusRing    =   True
         Visible         =   True
         Width           =   120
      End
      Begin PushButton SetupAdminBtn
         AutoDeactivate  =   True
         Bold            =   False
         ButtonStyle     =   "0"
         Cancel          =   False
         Caption         =   "Setup / Admin functions"
         Default         =   False
         Enabled         =   True
         Height          =   76
         HelpTag         =   ""
         Index           =   -2147483648
         InitialParent   =   "MainPanel"
         Italic          =   False
         Left            =   20
         LockBottom      =   True
         LockedInPosition=   False
         LockLeft        =   True
         LockRight       =   False
         LockTop         =   False
         Scope           =   0
         TabIndex        =   8
         TabPanelIndex   =   1
         TabStop         =   True
         TextFont        =   "System"
         TextSize        =   16.0
         TextUnit        =   0
         Top             =   598
         Transparent     =   False
         Underline       =   False
         Visible         =   True
         Width           =   395
      End
      Begin Label Label1
         AutoDeactivate  =   True
         Bold            =   False
         DataField       =   ""
         DataSource      =   ""
         Enabled         =   True
         Height          =   54
         HelpTag         =   ""
         Index           =   -2147483648
         InitialParent   =   "MainPanel"
         Italic          =   False
         Left            =   177
         LockBottom      =   False
         LockedInPosition=   False
         LockLeft        =   True
         LockRight       =   True
         LockTop         =   True
         Multiline       =   False
         Scope           =   0
         Selectable      =   False
         TabIndex        =   9
         TabPanelIndex   =   1
         TabStop         =   True
         Text            =   "thirdway"
         TextAlign       =   1
         TextColor       =   &c00000000
         TextFont        =   "System"
         TextSize        =   33.0
         TextUnit        =   0
         Top             =   10
         Transparent     =   True
         Underline       =   False
         Visible         =   True
         Width           =   206
      End
      Begin Label Label2
         AutoDeactivate  =   True
         Bold            =   False
         DataField       =   ""
         DataSource      =   ""
         Enabled         =   True
         Height          =   54
         HelpTag         =   ""
         Index           =   -2147483648
         InitialParent   =   "MainPanel"
         Italic          =   False
         Left            =   20
         LockBottom      =   False
         LockedInPosition=   False
         LockLeft        =   True
         LockRight       =   True
         LockTop         =   True
         Multiline       =   False
         Scope           =   0
         Selectable      =   False
         TabIndex        =   0
         TabPanelIndex   =   2
         TabStop         =   True
         Text            =   "Setup / Admin functions"
         TextAlign       =   1
         TextColor       =   &c00000000
         TextFont        =   "System"
         TextSize        =   33.0
         TextUnit        =   0
         Top             =   20
         Transparent     =   True
         Underline       =   False
         Visible         =   True
         Width           =   395
      End
      Begin Label Label3
         AutoDeactivate  =   True
         Bold            =   False
         DataField       =   ""
         DataSource      =   ""
         Enabled         =   True
         Height          =   54
         HelpTag         =   ""
         Index           =   -2147483648
         InitialParent   =   "MainPanel"
         Italic          =   False
         Left            =   20
         LockBottom      =   False
         LockedInPosition=   False
         LockLeft        =   True
         LockRight       =   True
         LockTop         =   True
         Multiline       =   False
         Scope           =   0
         Selectable      =   False
         TabIndex        =   0
         TabPanelIndex   =   3
         TabStop         =   True
         Text            =   "Controller"
         TextAlign       =   1
         TextColor       =   &c00000000
         TextFont        =   "System"
         TextSize        =   33.0
         TextUnit        =   0
         Top             =   20
         Transparent     =   True
         Underline       =   False
         Visible         =   True
         Width           =   395
      End
      Begin Label Label4
         AutoDeactivate  =   True
         Bold            =   False
         DataField       =   ""
         DataSource      =   ""
         Enabled         =   True
         Height          =   54
         HelpTag         =   ""
         Index           =   -2147483648
         InitialParent   =   "MainPanel"
         Italic          =   False
         Left            =   20
         LockBottom      =   False
         LockedInPosition=   False
         LockLeft        =   True
         LockRight       =   True
         LockTop         =   True
         Multiline       =   False
         Scope           =   0
         Selectable      =   False
         TabIndex        =   0
         TabPanelIndex   =   4
         TabStop         =   True
         Text            =   "Client"
         TextAlign       =   1
         TextColor       =   &c00000000
         TextFont        =   "System"
         TextSize        =   33.0
         TextUnit        =   0
         Top             =   20
         Transparent     =   True
         Underline       =   False
         Visible         =   True
         Width           =   395
      End
      Begin Label Label5
         AutoDeactivate  =   True
         Bold            =   False
         DataField       =   ""
         DataSource      =   ""
         Enabled         =   True
         Height          =   54
         HelpTag         =   ""
         Index           =   -2147483648
         InitialParent   =   "MainPanel"
         Italic          =   False
         Left            =   152
         LockBottom      =   False
         LockedInPosition=   False
         LockLeft        =   True
         LockRight       =   True
         LockTop         =   True
         Multiline       =   True
         Scope           =   0
         Selectable      =   False
         TabIndex        =   10
         TabPanelIndex   =   1
         TabStop         =   True
         Text            =   "an experiment in content services architecture"
         TextAlign       =   1
         TextColor       =   &c00000000
         TextFont        =   "System"
         TextSize        =   20.0
         TextUnit        =   0
         Top             =   62
         Transparent     =   True
         Underline       =   False
         Visible         =   True
         Width           =   263
      End
      Begin Label Label6
         AutoDeactivate  =   True
         Bold            =   False
         DataField       =   ""
         DataSource      =   ""
         Enabled         =   True
         Height          =   29
         HelpTag         =   ""
         Index           =   -2147483648
         InitialParent   =   "MainPanel"
         Italic          =   False
         Left            =   20
         LockBottom      =   False
         LockedInPosition=   False
         LockLeft        =   True
         LockRight       =   True
         LockTop         =   True
         Multiline       =   False
         Scope           =   0
         Selectable      =   False
         TabIndex        =   11
         TabPanelIndex   =   1
         TabStop         =   True
         Text            =   "Launch role :"
         TextAlign       =   0
         TextColor       =   &c00000000
         TextFont        =   "System"
         TextSize        =   20.0
         TextUnit        =   0
         Top             =   258
         Transparent     =   True
         Underline       =   False
         Visible         =   True
         Width           =   164
      End
      Begin GroupBox InitGroupBox
         AutoDeactivate  =   True
         Bold            =   False
         Caption         =   "Schema && VFS Initialization"
         Enabled         =   True
         Height          =   189
         HelpTag         =   ""
         Index           =   -2147483648
         InitialParent   =   "MainPanel"
         Italic          =   False
         Left            =   20
         LockBottom      =   False
         LockedInPosition=   False
         LockLeft        =   True
         LockRight       =   False
         LockTop         =   True
         Scope           =   0
         TabIndex        =   2
         TabPanelIndex   =   2
         TabStop         =   True
         TextFont        =   "System"
         TextSize        =   16.0
         TextUnit        =   0
         Top             =   102
         Transparent     =   False
         Underline       =   False
         Visible         =   True
         Width           =   395
         Begin Label TablespaceLabel
            AutoDeactivate  =   True
            Bold            =   False
            DataField       =   ""
            DataSource      =   ""
            Enabled         =   True
            Height          =   25
            HelpTag         =   ""
            Index           =   -2147483648
            InitialParent   =   "InitGroupBox"
            Italic          =   False
            Left            =   40
            LockBottom      =   False
            LockedInPosition=   False
            LockLeft        =   True
            LockRight       =   False
            LockTop         =   True
            Multiline       =   False
            Scope           =   0
            Selectable      =   False
            TabIndex        =   0
            TabPanelIndex   =   2
            TabStop         =   True
            Text            =   "Tablespace path"
            TextAlign       =   0
            TextColor       =   &c00000000
            TextFont        =   "System"
            TextSize        =   16.0
            TextUnit        =   0
            Top             =   144
            Transparent     =   False
            Underline       =   False
            Visible         =   True
            Width           =   124
         End
         Begin TextField TablespaceField
            AcceptTabs      =   False
            Alignment       =   0
            AutoDeactivate  =   True
            AutomaticallyCheckSpelling=   False
            BackColor       =   &cFFFFFF00
            Bold            =   False
            Border          =   True
            CueText         =   ""
            DataField       =   ""
            DataSource      =   ""
            Enabled         =   True
            Format          =   ""
            Height          =   25
            HelpTag         =   ""
            Index           =   -2147483648
            InitialParent   =   "InitGroupBox"
            Italic          =   False
            Left            =   176
            LimitText       =   0
            LockBottom      =   False
            LockedInPosition=   False
            LockLeft        =   True
            LockRight       =   False
            LockTop         =   True
            Mask            =   ""
            Password        =   False
            ReadOnly        =   False
            Scope           =   0
            TabIndex        =   1
            TabPanelIndex   =   2
            TabStop         =   True
            Text            =   "c:\\thirdway"
            TextColor       =   &c00000000
            TextFont        =   "System"
            TextSize        =   14.0
            TextUnit        =   0
            Top             =   144
            Transparent     =   False
            Underline       =   False
            UseFocusRing    =   True
            Visible         =   True
            Width           =   219
         End
         Begin PushButton initBtn
            AutoDeactivate  =   True
            Bold            =   False
            ButtonStyle     =   "0"
            Cancel          =   False
            Caption         =   "Initialize"
            Default         =   False
            Enabled         =   True
            Height          =   36
            HelpTag         =   ""
            Index           =   -2147483648
            InitialParent   =   "InitGroupBox"
            Italic          =   False
            Left            =   176
            LockBottom      =   False
            LockedInPosition=   False
            LockLeft        =   True
            LockRight       =   False
            LockTop         =   True
            Scope           =   0
            TabIndex        =   2
            TabPanelIndex   =   2
            TabStop         =   True
            TextFont        =   "System"
            TextSize        =   16.0
            TextUnit        =   0
            Top             =   232
            Transparent     =   False
            Underline       =   False
            Visible         =   True
            Width           =   219
         End
         Begin TextField VFSpathField
            AcceptTabs      =   False
            Alignment       =   0
            AutoDeactivate  =   True
            AutomaticallyCheckSpelling=   False
            BackColor       =   &cFFFFFF00
            Bold            =   False
            Border          =   True
            CueText         =   ""
            DataField       =   ""
            DataSource      =   ""
            Enabled         =   True
            Format          =   ""
            Height          =   25
            HelpTag         =   ""
            Index           =   -2147483648
            InitialParent   =   "InitGroupBox"
            Italic          =   False
            Left            =   176
            LimitText       =   0
            LockBottom      =   False
            LockedInPosition=   False
            LockLeft        =   True
            LockRight       =   False
            LockTop         =   True
            Mask            =   ""
            Password        =   False
            ReadOnly        =   False
            Scope           =   0
            TabIndex        =   4
            TabPanelIndex   =   2
            TabStop         =   True
            Text            =   "C:\\thirdway"
            TextColor       =   &c00000000
            TextFont        =   "System"
            TextSize        =   14.0
            TextUnit        =   0
            Top             =   181
            Transparent     =   False
            Underline       =   False
            UseFocusRing    =   True
            Visible         =   True
            Width           =   219
         End
         Begin Label VFSpathLabel
            AutoDeactivate  =   True
            Bold            =   False
            DataField       =   ""
            DataSource      =   ""
            Enabled         =   True
            Height          =   25
            HelpTag         =   ""
            Index           =   -2147483648
            InitialParent   =   "InitGroupBox"
            Italic          =   False
            Left            =   40
            LockBottom      =   False
            LockedInPosition=   False
            LockLeft        =   True
            LockRight       =   False
            LockTop         =   True
            Multiline       =   False
            Scope           =   0
            Selectable      =   False
            TabIndex        =   3
            TabPanelIndex   =   2
            TabStop         =   True
            Text            =   "VFS root path"
            TextAlign       =   0
            TextColor       =   &c00000000
            TextFont        =   "System"
            TextSize        =   16.0
            TextUnit        =   0
            Top             =   181
            Transparent     =   False
            Underline       =   False
            Visible         =   True
            Width           =   124
         End
         Begin PushButton rollbackBtn
            AutoDeactivate  =   True
            Bold            =   False
            ButtonStyle     =   "0"
            Cancel          =   False
            Caption         =   "Cleanup"
            Default         =   False
            Enabled         =   True
            Height          =   36
            HelpTag         =   "Deletes all thirdway-related database objects"
            Index           =   -2147483648
            InitialParent   =   "InitGroupBox"
            Italic          =   False
            Left            =   40
            LockBottom      =   False
            LockedInPosition=   False
            LockLeft        =   True
            LockRight       =   False
            LockTop         =   True
            Scope           =   0
            TabIndex        =   5
            TabPanelIndex   =   2
            TabStop         =   True
            TextFont        =   "System"
            TextSize        =   16.0
            TextUnit        =   0
            Top             =   232
            Transparent     =   False
            Underline       =   False
            Visible         =   True
            Width           =   124
         End
      End
      Begin PushButton testPushBtn
         AutoDeactivate  =   True
         Bold            =   False
         ButtonStyle     =   "0"
         Cancel          =   False
         Caption         =   "Test push"
         Default         =   False
         Enabled         =   True
         Height          =   58
         HelpTag         =   ""
         Index           =   -2147483648
         InitialParent   =   "MainPanel"
         Italic          =   False
         Left            =   102
         LockBottom      =   False
         LockedInPosition=   False
         LockLeft        =   True
         LockRight       =   False
         LockTop         =   True
         Scope           =   0
         TabIndex        =   1
         TabPanelIndex   =   4
         TabStop         =   True
         TextFont        =   "System"
         TextSize        =   16.0
         TextUnit        =   0
         Top             =   102
         Transparent     =   False
         Underline       =   False
         Visible         =   True
         Width           =   231
      End
   End
   Begin Listbox log
      AutoDeactivate  =   True
      AutoHideScrollbars=   True
      Bold            =   False
      Border          =   True
      ColumnCount     =   1
      ColumnsResizable=   False
      ColumnWidths    =   ""
      DataField       =   ""
      DataSource      =   ""
      DefaultRowHeight=   -1
      Enabled         =   True
      EnableDrag      =   False
      EnableDragReorder=   False
      GridLinesHorizontal=   0
      GridLinesVertical=   0
      HasHeading      =   False
      HeadingIndex    =   -1
      Height          =   613
      HelpTag         =   ""
      Hierarchical    =   False
      Index           =   -2147483648
      InitialParent   =   ""
      InitialValue    =   ""
      Italic          =   False
      Left            =   447
      LockBottom      =   True
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      RequiresSelection=   False
      Scope           =   0
      ScrollbarHorizontal=   False
      ScrollBarVertical=   True
      SelectionType   =   0
      ShowDropIndicator=   False
      TabIndex        =   1
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   16.0
      TextUnit        =   0
      Top             =   61
      Transparent     =   False
      Underline       =   False
      UseFocusRing    =   True
      Visible         =   True
      Width           =   443
      _ScrollOffset   =   0
      _ScrollWidth    =   -1
   End
   Begin Label Label7
      AutoDeactivate  =   True
      Bold            =   False
      DataField       =   ""
      DataSource      =   ""
      Enabled         =   True
      Height          =   29
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   False
      Left            =   447
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   False
      LockTop         =   True
      Multiline       =   False
      Scope           =   0
      Selectable      =   False
      TabIndex        =   2
      TabPanelIndex   =   0
      TabStop         =   True
      Text            =   "Main Log :"
      TextAlign       =   0
      TextColor       =   &c00000000
      TextFont        =   "System"
      TextSize        =   20.0
      TextUnit        =   0
      Top             =   20
      Transparent     =   True
      Underline       =   False
      Visible         =   True
      Width           =   164
   End
End
#tag EndWindow

#tag WindowCode
	#tag Event
		Sub Open()
		  autofillCredentials
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub autofillCredentials()
		  dim pgpass as FolderItem = SpecialFolder.UserHome.Child("pgservice.txt")
		  
		  if pgpass.Exists then
		    
		    dim inputStream as TextInputStream
		    inputStream = TextInputStream.Open(pgpass)
		    
		    hostField.Text = inputStream.ReadLine
		    portField.Text = inputStream.ReadLine
		    databasenameField.Text = inputStream.ReadLine
		    usernameField.Text = inputStream.ReadLine
		    passwordField.Text = inputStream.ReadLine
		    
		    inputStream.Close
		    
		  end if
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function initThirdway(tablespaceFoldername as String, VFSfoldername as String) As String
		  if IsNull(db) then return "No database session"
		  if tablespaceFoldername.Trim = "" or VFSfoldername.Trim = "" then return "Init error: no tablespace or vfs path"
		  
		  db.SQLExecute("CREATE TABLESPACE thirdway LOCATION '" + tablespaceFoldername + "'")
		  if db.Error then Return db.ErrorMessage
		  writeLog("...tablespace created")
		  
		  db.SQLExecute("CREATE SCHEMA thirdway")
		  if db.Error then Return db.ErrorMessage
		  writeLog("...schema created")
		  
		  // store settings on db
		  db.SQLExecute("CREATE TABLE thirdway.conf (key TEXT PRIMARY KEY , value TEXT) TABLESPACE thirdway")
		  if db.Error then Return db.ErrorMessage
		  writeLog("...conf table created")
		  
		  // this is the document table
		  db.SQLExecute("CREATE TABLE thirdway.repository(docid UUID PRIMARY KEY , creationstamp TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now() , userdata TEXT NOT NULL , importduration BIGINT , valid BOOLEAN NOT NULL DEFAULT FALSE) TABLESPACE thirdway")
		  if db.Error then Return db.ErrorMessage
		  writeLog("...repository table created")
		  
		  db.SQLExecute("CREATE TYPE thirdway.cache_action AS ENUM ('push' , 'pull' , 'invalid')")
		  if db.Error then Return db.ErrorMessage
		  writeLog("...cached object states enumeration created")
		  
		  // this is the content cache
		  db.SQLExecute("CREATE UNLOGGED TABLE thirdway.cache(fragmentid UUID PRIMARY KEY , creationstamp TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now() , docid UUID , indx INTEGER NOT NULL , lastfragment BOOLEAN NOT NULL , action  thirdway.cache_action NOT NULL , content BYTEA ) TABLESPACE thirdway")
		  if db.Error then Return db.ErrorMessage
		  writeLog("...cache table created")
		  
		  
		  // create a limnie
		  dim newLimnie as new Limnie.VFS
		  newLimnie.name = "thirdway"
		  newLimnie.friendlyName = "the thirdway single-pool limnie"
		  newLimnie.file = GetFolderItem(VFSfoldername).Child("thirdway.limnie")
		  newLimnie.description = "this is just a test"
		  
		  newLimnie = Limnie.createLimnie(newLimnie)
		  if newLimnie.error then Return "Limnie error: " + newLimnie.errorMessage
		  writeLog("...Limnie created")
		  
		  
		  dim initLimnieSession as new Limnie.Session(newLimnie)
		  if initLimnieSession.getLastError <> "" then return "Limnie error: " + initLimnieSession.getLastError
		  writeLog("...Limnie mounted")
		  
		  
		  // create the first and only pool
		  dim newPool as new Limnie.Pool
		  newPool.autoExpand = true
		  newPool.name = "defaultpool"
		  newPool.friendlyName = "The default pool"
		  newPool.mediumThreshold = 512
		  newPool.rootFolder = GetFolderItem(VFSfoldername)
		  
		  newPool = initLimnieSession.createNewPool(newPool)
		  if newPool.error then Return "Limnie error: " + newPool.errorMessage
		  writeLog("...Limnie default pool created")
		  
		  initLimnieSession.Close
		  
		  db.SQLExecute("INSERT INTO thirdway.conf VALUES ('limnie_path' , '" +  newLimnie.file.NativePath + "')")
		  if db.Error then Return db.ErrorMessage
		  writeLog("...Limnie registered")
		  
		  
		  return ""
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub PushConcludedHandler(sender as thirdwayClient, requestData as pgReQ_request)
		  writeLog("Push concluded: " + if(requestData.Error , requestData.ErrorMessage , "OK"))
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RequestExpired(sender as pgReQ_session, ExpiredRequest as pgReQ_request)
		  writeLog("Expired request: " + ExpiredRequest.UUID)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RequestReceived(sender as pgReQ_session, UUID as string)
		  // dim newRequest as pgReQ_request = reqSession.getRequestReceived(UUID)
		  // if newRequest.Error then Return
		  // 
		  // dim row(7) as string
		  // 
		  // row(0) = newRequest.UUID
		  // row(1) = newRequest.Type
		  // row(2) = newRequest.creationStamp.SQLDateTime
		  // row(3) = if(isnull(newRequest.getParameter("CLEARTEXT")) , "" , newRequest.getParameter("CLEARTEXT").StringValue)
		  // row(4) = str(newRequest.TimeoutCountdown)
		  // row(5) = newRequest.ResponseChannel
		  // row(6) = ""  // we haven't responded yet
		  // row(7) = ""  // likewise
		  // 
		  // RequestList.AddRow row
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub rollbackInit()
		  // might not succeed, but we try it anyway
		  
		  if IsNull(db) then
		    writeLog("db is not open")
		    return
		  end if
		  
		  db.SQLExecute("DROP SCHEMA thirdway CASCADE")
		  writeLog(if(db.Error , "Error dropping schema: " + db.ErrorMessage , "Schema dropped"))
		  
		  db.SQLExecute("DROP TABLESPACE thirdway")
		  writeLog(if(db.Error , "Error dropping tablespace: " + db.ErrorMessage , "Tablespace dropped"))
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ServiceInterrupted(sender as pgReQ_session, errorMsg as string)
		  writeLog("")
		  writeLog("Service interrupted!")
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetMode(targetMode as AppMode)
		  if IsNull(db) then
		    writeLog("Not connected to db: cannot set role")
		    return
		  end if
		  
		  
		  Mode = targetMode
		  
		  select case Mode
		  case AppMode.Client
		    
		    clientSession = new thirdwayClient(db)
		    if clientSession.LastError = "" then
		      AddHandler clientSession.PushConcluded , WeakAddressOf PushConcludedHandler
		      
		      MainPanel.Value = 3
		      writeLog("Client role selected")
		      Title = "thirdway - client"
		      
		      writeLog("Client session created")
		      
		    else
		      
		      writeLog("Client session fail: " + clientSession.LastError)
		      
		    end if
		    
		  case AppMode.Controller
		    MainPanel.Value = 2
		    writeLog("Controller role selected")
		    Title = "thirdway - controller"
		  case AppMode.Setup
		    MainPanel.Value = 1
		    writeLog("Setup/Admin functions")
		    Title = "thirdway - setup"
		  end Select
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub writeLog(entry as string)
		  log.AddRow entry
		  log.ListIndex = log.LastIndex
		  
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h0
		clientSession As thirdwayClient
	#tag EndProperty

	#tag Property, Flags = &h0
		db As PostgreSQLDatabase
	#tag EndProperty

	#tag Property, Flags = &h0
		Mode As AppMode
	#tag EndProperty

	#tag Property, Flags = &h0
		reqSession As pgReQ_session
	#tag EndProperty


	#tag Enum, Name = AppMode, Type = Integer, Flags = &h0
		Setup
		  Client
		Controller
	#tag EndEnum


#tag EndWindowCode

#tag Events ClientModeBtn
	#tag Event
		Sub Action()
		  SetMode(AppMode.Client)
		  
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events ControllerModeBtn
	#tag Event
		Sub Action()
		  SetMode(AppMode.Controller)
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events passwordField
	#tag Event
		Sub Open()
		  
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events ConnectBtn
	#tag Event
		Sub Action()
		  log.DeleteAllRows
		  
		  db = new PostgreSQLDatabase
		  
		  db.AppName = "thirdway"
		  db.Host = hostField.Text.Trim
		  db.Port = portField.Text.Trim.Val
		  db.DatabaseName = databasenameField.Text.Trim
		  db.UserName = usernameField.Text.Trim
		  db.Password = passwordField.Text.Trim
		  
		  if db.Connect = false then 
		    writeLog("error connecting")
		    writeLog(db.ErrorMessage)
		    db = nil
		    return
		  else
		    writeLog("connected to db")
		  end if
		  
		  // listen to "controller" channel and accept "HASH" requests
		  // reqSession = new pgReQ_session(db , Array("controller") , Array(new pgReQ_request("HASH" , 10 , true)))
		  // 
		  // if reqSession.LastError <> "" then
		  // log.AddRow "error creating req session"
		  // log.AddRow reqSession.LastError
		  // Return
		  // 
		  // else
		  // log.AddRow "initialized queue"
		  // end if
		  // 
		  // log.AddRow "pid: " + str(reqSession.PID)
		  // 
		  // dim channelsListening() as String = reqSession.getChannelsListening
		  // for i as Integer = 0 to channelsListening.Ubound
		  // log.AddRow "listening to channel: " + channelsListening(i)
		  // next i
		  // 
		  // AddHandler reqSession.ServiceInterrupted , WeakAddressOf ServiceInterrupted
		  // AddHandler reqSession.RequestReceived , WeakAddressOf RequestReceived
		  // AddHandler reqSession.RequestExpired , WeakAddressOf RequestExpired
		  
		  
		  
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events SetupAdminBtn
	#tag Event
		Sub Action()
		  SetMode(AppMode.Setup)
		  
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events initBtn
	#tag Event
		Sub Action()
		  dim outcome as String = initThirdway(TablespaceField.Text.Trim , VFSpathField.Text.Trim)
		  
		  writeLog(if(outcome = "" , "init OK" , outcome))
		  
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events rollbackBtn
	#tag Event
		Sub Action()
		  rollbackInit
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events testPushBtn
	#tag Event
		Sub Action()
		  dim sourceFile as FolderItem = GetOpenFolderItem("*.*")
		  if IsNull(sourceFile) then return
		  
		  dim source as BinaryStream = BinaryStream.Open(sourceFile , false)
		  
		  dim newRecord as new DatabaseRecord
		  
		  dim userdata as Int64 = Microseconds
		  newRecord.Column("userdata") = str(userdata)
		  
		  dim pushOutcome as string = clientSession.CreateDocument(source , newRecord)
		  
		  writeLog(if(pushOutcome = "" , clientSession.LastError , pushOutcome))
		  
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events log
	#tag Event
		Sub DoubleClick()
		  Dim row, column As Integer
		  row = Me.RowFromXY(System.MouseX - Me.Left - Self.Left, System.MouseY - Me.Top - Self.Top)
		  column = Me.ColumnFromXY(System.MouseX - Me.Left - Self.Left, System.MouseY - Me.Top - Self.Top)
		  
		  dim c as new Clipboard
		  c.SetText(me.cell(row,0))
		  c.Close
		  
		End Sub
	#tag EndEvent
#tag EndEvents
#tag ViewBehavior
	#tag ViewProperty
		Name="Name"
		Visible=true
		Group="ID"
		Type="String"
		EditorType="String"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Interfaces"
		Visible=true
		Group="ID"
		Type="String"
		EditorType="String"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Super"
		Visible=true
		Group="ID"
		Type="String"
		EditorType="String"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Width"
		Visible=true
		Group="Size"
		InitialValue="600"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Height"
		Visible=true
		Group="Size"
		InitialValue="400"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MinWidth"
		Visible=true
		Group="Size"
		InitialValue="64"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MinHeight"
		Visible=true
		Group="Size"
		InitialValue="64"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MaxWidth"
		Visible=true
		Group="Size"
		InitialValue="32000"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MaxHeight"
		Visible=true
		Group="Size"
		InitialValue="32000"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Frame"
		Visible=true
		Group="Frame"
		InitialValue="0"
		Type="Integer"
		EditorType="Enum"
		#tag EnumValues
			"0 - Document"
			"1 - Movable Modal"
			"2 - Modal Dialog"
			"3 - Floating Window"
			"4 - Plain Box"
			"5 - Shadowed Box"
			"6 - Rounded Window"
			"7 - Global Floating Window"
			"8 - Sheet Window"
			"9 - Metal Window"
			"11 - Modeless Dialog"
		#tag EndEnumValues
	#tag EndViewProperty
	#tag ViewProperty
		Name="Title"
		Visible=true
		Group="Frame"
		InitialValue="Untitled"
		Type="String"
	#tag EndViewProperty
	#tag ViewProperty
		Name="CloseButton"
		Visible=true
		Group="Frame"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Resizeable"
		Visible=true
		Group="Frame"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MaximizeButton"
		Visible=true
		Group="Frame"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MinimizeButton"
		Visible=true
		Group="Frame"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="FullScreenButton"
		Visible=true
		Group="Frame"
		InitialValue="False"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Composite"
		Group="OS X (Carbon)"
		InitialValue="False"
		Type="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MacProcID"
		Group="OS X (Carbon)"
		InitialValue="0"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="FullScreen"
		Group="Behavior"
		InitialValue="False"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="ImplicitInstance"
		Visible=true
		Group="Behavior"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="LiveResize"
		Group="Behavior"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Placement"
		Visible=true
		Group="Behavior"
		InitialValue="0"
		Type="Integer"
		EditorType="Enum"
		#tag EnumValues
			"0 - Default"
			"1 - Parent Window"
			"2 - Main Screen"
			"3 - Parent Window Screen"
			"4 - Stagger"
		#tag EndEnumValues
	#tag EndViewProperty
	#tag ViewProperty
		Name="Visible"
		Visible=true
		Group="Behavior"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="HasBackColor"
		Visible=true
		Group="Background"
		InitialValue="False"
		Type="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="BackColor"
		Visible=true
		Group="Background"
		InitialValue="&hFFFFFF"
		Type="Color"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Backdrop"
		Visible=true
		Group="Background"
		Type="Picture"
		EditorType="Picture"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MenuBar"
		Visible=true
		Group="Menus"
		Type="MenuBar"
		EditorType="MenuBar"
	#tag EndViewProperty
	#tag ViewProperty
		Name="MenuBarVisible"
		Visible=true
		Group="Deprecated"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Mode"
		Group="Behavior"
		Type="AppMode"
		EditorType="Enum"
		#tag EnumValues
			"0 - Setup"
			"1 - Client"
			"2 - Controller"
		#tag EndEnumValues
	#tag EndViewProperty
#tag EndViewBehavior