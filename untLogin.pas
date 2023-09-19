unit untLogin;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TabControl,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, uLoading;

type
  TfrmLogin = class(TForm)
    TabControlLogin: TTabControl;
    TabLogin: TTabItem;
    TabConta1: TTabItem;
    TabConta2: TTabItem;
    Image1: TImage;
    Layout1: TLayout;
    Label1: TLabel;
    edtLoginEmail: TEdit;
    btnAcessar: TButton;
    lblCriarConta: TLabel;
    lblTenhoConta: TLabel;
    Layout2: TLayout;
    Label4: TLabel;
    btnProximo: TButton;
    Label5: TLabel;
    lblTenhoConta2: TLabel;
    Layout3: TLayout;
    Label7: TLabel;
    btnCriarConta: TButton;
    Label8: TLabel;
    StyleBookLogin: TStyleBook;
    RectLoginEmail: TRectangle;
    RectLoginSenha: TRectangle;
    edtLoginSenha: TEdit;
    RectCriarNome: TRectangle;
    edtCriarNome: TEdit;
    RectCriarSenha: TRectangle;
    edtCriarSenha: TEdit;
    RectCriarEmail: TRectangle;
    edtCriarEmail: TEdit;
    RectCriarEnd: TRectangle;
    edtCriarEnd: TEdit;
    RectCriarBairro: TRectangle;
    edtCriarBairro: TEdit;
    RectCriarCep: TRectangle;
    edtCriarCep: TEdit;
    RectCriarUF: TRectangle;
    edtCriarUF: TEdit;
    RectCriarCdd: TRectangle;
    edtCriarCdd: TEdit;
    Layout4: TLayout;
    imgVoltar: TImage;
    procedure btnAcessarClick(Sender: TObject);
    procedure lblCriarContaClick(Sender: TObject);
    procedure lblTenhoContaClick(Sender: TObject);
    procedure btnProximoClick(Sender: TObject);
    procedure btnCriarContaClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    procedure ThreadLoginTerminate(Sender: TObject);
    procedure ThreadShowTerminate(Sender: TObject);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmLogin: TfrmLogin;

implementation

{$R *.fmx}

uses untPrincipal, untDmUsuarios, uSession;

procedure TfrmLogin.ThreadLoginTerminate(Sender: TObject);
begin
  TLoading.Hide;

  if Sender is TThread then
    begin
        if Assigned(TThread(Sender).FatalException) then
          begin
            ShowMessage(Exception(TThread(Sender).FatalException).Message);
            Exit;
          end;
    end;

  if not Assigned(frmPrincipal) then
    Application.CreateForm(TfrmPrincipal, frmPrincipal);

  try
    DmUsuarios.ListarUsuarioLocal;
  except
  end;

  frmPrincipal.lblMenuNome.Text := DmUsuarios.FDQryUsuario.FieldByName('NOME').AsString;
  frmPrincipal.lblMenuEmail.Text := DmUsuarios.FDQryUsuario.FieldByName('EMAIL').AsString;
  TSession.ID_USUARIO := DmUsuarios.FDQryUsuario.FieldByName('ID_USUARIO').AsInteger;

  Application.MainForm := frmPrincipal;
  frmPrincipal.Show;
  frmLogin.Close;
end;

procedure TfrmLogin.ThreadShowTerminate(Sender: TObject);
begin
  TLoading.Hide;

  if Sender is TThread then
    begin
        if Assigned(TThread(Sender).FatalException) then
          begin
            ShowMessage(Exception(TThread(Sender).FatalException).Message);
            Exit;
          end;
    end;

  if DmUsuarios.FDQryUsuario.RecordCount > 0 then
    begin
      if not Assigned(frmPrincipal) then
        Application.CreateForm(TfrmPrincipal, frmPrincipal);

      Application.MainForm := frmPrincipal;

      frmPrincipal.lblMenuNome.Text := DmUsuarios.FDQryUsuario.FieldByName('NOME').Value;
      frmPrincipal.lblMenuEmail.Text := DmUsuarios.FDQryUsuario.FieldByName('EMAIL').Value;
      TSession.ID_USUARIO := DmUsuarios.FDQryUsuario.FieldByName('ID_USUARIO').AsInteger;

      frmPrincipal.Show;
      frmLogin.Close;
    end;
end;

procedure TfrmLogin.lblTenhoContaClick(Sender: TObject);
begin
  imgVoltar.Visible := False;
  TabControlLogin.GotoVisibleTab(0);
end;

procedure TfrmLogin.btnCriarContaClick(Sender: TObject);
var
  t: TThread;
begin
  TLoading.Show(frmLogin, '');

  t := TThread.CreateAnonymousThread(procedure
  begin
    DmUsuarios.CriarConta(edtCriarNome.Text, edtCriarEmail.Text, edtCriarSenha.Text, edtCriarEnd.Text,
                          edtCriarBairro.Text, edtCriarCdd.Text, edtCriarUF.Text, edtCriarCep.Text);

    with DmUsuarios.TabUsuario do
      begin
        if RecordCount > 0 then
          begin
            DmUsuarios.SalvarUsuarioLocal(FieldByName('id_usuario').AsInteger,
                                          edtCriarEmail.Text,
                                          edtCriarNome.Text,
                                          edtCriarEnd.Text,
                                          edtCriarBairro.Text,
                                          edtCriarCdd.Text,
                                          edtCriarUF.Text,
                                          edtCriarCep.Text);
          end;
      end;
  end);

  t.OnTerminate := ThreadLoginTerminate;
  t.Start;
end;

procedure TfrmLogin.btnProximoClick(Sender: TObject);
begin
  imgVoltar.Visible := True;
  TabControlLogin.GotoVisibleTab(2);
end;

procedure TfrmLogin.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
  frmLogin := nil;
end;

procedure TfrmLogin.FormShow(Sender: TObject);
var
  t: TThread;
begin
  TLoading.Show(frmLogin, '');

  t := TThread.CreateAnonymousThread(procedure
  begin
    DmUsuarios.ListarUsuarioLocal;
  end);

  t.OnTerminate := ThreadShowTerminate;
  t.Start;
end;

procedure TfrmLogin.lblCriarContaClick(Sender: TObject);
begin
  imgVoltar.Visible := False;
  TabControlLogin.GotoVisibleTab(1);
end;

procedure TfrmLogin.btnAcessarClick(Sender: TObject);
var
  t: TThread;
begin
  TLoading.Show(frmLogin, '');

  t := TThread.CreateAnonymousThread(procedure
  begin
    DmUsuarios.Login(edtLoginEmail.Text, edtLoginSenha.Text);

    with DmUsuarios.TabUsuario do
      begin
        if RecordCount > 0 then
          begin
            DmUsuarios.SalvarUsuarioLocal(FieldByName('id_usuario').AsInteger,
                                          FieldByName('email').AsString,
                                          FieldByName('nome').AsString,
                                          FieldByName('endereco').AsString,
                                          FieldByName('bairro').AsString,
                                          FieldByName('cidade').AsString,
                                          FieldByName('uf').AsString,
                                          FieldByName('cep').AsString);
          end;
      end;
  end);

  t.OnTerminate := ThreadLoginTerminate;
  t.Start;
end;

end.
