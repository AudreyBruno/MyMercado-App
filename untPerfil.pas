unit untPerfil;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit;

type
  TfrmPerfil = class(TForm)
    LayoutCabecalho: TLayout;
    lblTitle: TLabel;
    imgVoltar: TImage;
    imgSalvar: TImage;
    Layout: TLayout;
    RectEnd: TRectangle;
    edtEnd: TEdit;
    RectBairro: TRectangle;
    edtBairro: TEdit;
    RectCep: TRectangle;
    edtCep: TEdit;
    Layout4: TLayout;
    RectCdd: TRectangle;
    edtCdd: TEdit;
    RectUF: TRectangle;
    edtUF: TEdit;
    RectNome: TRectangle;
    edtNome: TEdit;
    RectEmail: TRectangle;
    edtEmail: TEdit;
    RectSenha: TRectangle;
    edtSenha: TEdit;
    procedure FormShow(Sender: TObject);
    procedure imgSalvarClick(Sender: TObject);
    procedure imgVoltarClick(Sender: TObject);
  private
    procedure CarregarDados;
    procedure ThreadDadosTerminate(Sender: TObject);
    procedure ThreadSalvarTerminate(Sender: TObject);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmPerfil: TfrmPerfil;

implementation

{$R *.fmx}

uses uLoading, untDmUsuarios, uSession, untPrincipal;

procedure TfrmPerfil.ThreadDadosTerminate(Sender: TObject);
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
end;

procedure TfrmPerfil.ThreadSalvarTerminate(Sender: TObject);
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

  Close;
end;

procedure TfrmPerfil.CarregarDados;
var
  t: TThread;
begin
  TLoading.Show(frmPerfil, '');


  t := TThread.CreateAnonymousThread(procedure
  begin
    DmUsuarios.ListarUsuarioId(TSession.ID_USUARIO);

    with DmUsuarios.TabUsuario do
      begin
        TThread.Synchronize(TThread.CurrentThread, procedure
          begin
            edtNome.Text := FieldByName('nome').AsString;
            edtEmail.Text := FieldByName('email').AsString;
            edtSenha.Text := FieldByName('senha').AsString;
            edtEnd.Text := FieldByName('endereco').AsString;
            edtBairro.Text := FieldByName('bairro').AsString;
            edtCep.Text := FieldByName('cep').AsString;
            edtCdd.Text := FieldByName('cidade').AsString;
            edtUF.Text := FieldByName('uf').AsString;
          end);
      end;
  end);

  t.OnTerminate := ThreadDadosTerminate;
  t.Start;
end;

procedure TfrmPerfil.FormShow(Sender: TObject);
begin
  CarregarDados;
end;

procedure TfrmPerfil.imgSalvarClick(Sender: TObject);
var
  t: TThread;
begin
  TLoading.Show(frmPerfil, '');
  t := TThread.CreateAnonymousThread(procedure
  begin
    DmUsuarios.EditarUsuario(TSession.ID_USUARIO, edtNome.Text, edtEmail.Text, edtSenha.Text, edtEnd.Text,
                                  edtBairro.Text, edtCdd.Text, edtUF.Text, edtCep.Text);

    DmUsuarios.SalvarUsuarioLocal(TSession.ID_USUARIO, edtEmail.Text, edtNome.Text, edtEnd.Text,
                                  edtBairro.Text, edtCdd.Text, edtUF.Text, edtCep.Text);

    frmPrincipal.lblMenuNome.Text := edtNome.Text;
    frmPrincipal.lblMenuEmail.Text := edtEmail.Text;
  end);

  t.OnTerminate := ThreadSalvarTerminate;
  t.Start;
end;

procedure TfrmPerfil.imgVoltarClick(Sender: TObject);
begin
  Close;
end;

end.
