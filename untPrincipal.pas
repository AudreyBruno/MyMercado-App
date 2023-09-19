unit untPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.Layouts, FMX.Edit,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView, FMX.Ani, uLoading;

type
  TfrmPrincipal = class(TForm)
    LayoutCabecalho: TLayout;
    imgMenu: TImage;
    imgCarinho: TImage;
    Label1: TLabel;
    LayoutPesquisa: TLayout;
    RectPesquisar: TRectangle;
    edtBuscaMercado: TEdit;
    StyleBookPrincipal: TStyleBook;
    Image3: TImage;
    btnBuscar: TButton;
    LayoutSwitch: TLayout;
    RectSwitch: TRectangle;
    RectSelecao: TRectangle;
    lblCasa: TLabel;
    lblRetirada: TLabel;
    ListViewMercados: TListView;
    imgShop: TImage;
    imgTaxa: TImage;
    imgPedidoMin: TImage;
    AnimationSelecao: TFloatAnimation;
    rectMenu: TRectangle;
    Image1: TImage;
    LayoutCabecalhoMenu: TLayout;
    lblTitle: TLabel;
    imgFecharMenu: TImage;
    Layout1: TLayout;
    lblMenuNome: TLabel;
    lblMenuEmail: TLabel;
    rectMenuPedidos: TRectangle;
    Label3: TLabel;
    rectMenuMeuPerfil: TRectangle;
    Label4: TLabel;
    rectMenuDesconectar: TRectangle;
    Label5: TLabel;
    AnimationMenu: TFloatAnimation;
    procedure FormShow(Sender: TObject);
    procedure ListViewMercadosItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure lblCasaClick(Sender: TObject);
    procedure imgCarinhoClick(Sender: TObject);
    procedure imgMenuClick(Sender: TObject);
    procedure imgFecharMenuClick(Sender: TObject);
    procedure rectMenuPedidosClick(Sender: TObject);
    procedure btnBuscarClick(Sender: TObject);
    procedure rectMenuDesconectarClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure AnimationMenuFinish(Sender: TObject);
    procedure rectMenuMeuPerfilClick(Sender: TObject);
  private
    FInd_Retira: string;
    FInd_Entrega: string;
    procedure AddMercadosLv(id_mercado: integer; nome, endereco: string;
      tx_entrega, vl_min_ped: double);
    procedure ListarMercados;
    procedure SelecionarEntrega(lbl: TLabel);
    procedure OpenMenu(ind: Boolean);
    procedure ThreadMercadosTerminate(Sender: TObject);
    { Private declarations }
  public
    property Ind_Entrega: string read FInd_Entrega write FInd_Entrega;
    property Ind_Retira: string read FInd_Retira write FInd_Retira;
    { Public declarations }
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.fmx}

uses untMercado, untCarrinho, untPedidos, untDmMercados, untDmUsuarios,
  untLogin, untPerfil;

procedure TfrmPrincipal.ThreadMercadosTerminate(Sender: TObject);
begin
  TLoading.Hide;
  ListViewMercados.EndUpdate;

  if Sender is TThread then
    begin
        if Assigned(TThread(Sender).FatalException) then
          begin
            ShowMessage(Exception(TThread(Sender).FatalException).Message);
            Exit;
          end;
    end;
end;

procedure TfrmPrincipal.AddMercadosLv(id_mercado: integer; nome, endereco: string; tx_entrega, vl_min_ped: double);
var
  img: TListItemImage;
  txt: TListItemText;
begin
  with  ListViewMercados.Items.Add do
    begin
      Height := 120;
      Tag := id_mercado;

      img := TListItemImage(Objects.FindDrawable('imgShop'));
      img.Bitmap := imgShop.Bitmap;

      img := TListItemImage(Objects.FindDrawable('imgTaxa'));
      img.Bitmap := imgTaxa.Bitmap;

      img := TListItemImage(Objects.FindDrawable('imgCompraMin'));
      img.Bitmap := imgPedidoMin.Bitmap;

      txt := TListItemText(Objects.FindDrawable('txtNome'));
      txt.Text := nome;

      txt := TListItemText(Objects.FindDrawable('txtEndereco'));
      txt.Text := endereco;

      txt := TListItemText(Objects.FindDrawable('txtTaxa'));
      txt.Text := 'Taxa de entrega: ' + FormatFloat('R$ #,##0.00', tx_entrega);

      txt := TListItemText(Objects.FindDrawable('txtCompraMin'));
      txt.Text := 'Compra mínima: ' + FormatFloat('R$ #,##0.00', vl_min_ped);
    end;
end;

procedure TfrmPrincipal.ListarMercados;
var
  t: TThread;
begin
  TLoading.Show(frmPrincipal, '');

  ListViewMercados.Items.Clear;
  ListViewMercados.BeginUpdate;

  t := TThread.CreateAnonymousThread(procedure
  var
    i: integer;
  begin
    DmMercados.ListarMercados(edtBuscaMercado.Text, Ind_Entrega, Ind_Retira);

    with DmMercados.TabMercado do
      begin
        for i := 0 to RecordCount - 1 do
          begin
            TThread.Synchronize(TThread.CurrentThread, procedure
                begin
                  AddMercadosLv(FieldByName('id_mercado').AsInteger,
                                FieldByName('nome').AsString,
                                FieldByName('endereco').AsString,
                                FieldByName('vl_entrega').AsFloat,
                                FieldByName('vl_compra_min').AsFloat);
                end);

            Next;
          end;
      end;
  end);

  t.OnTerminate := ThreadMercadosTerminate;
  t.Start;
end;

procedure TfrmPrincipal.SelecionarEntrega(lbl: TLabel);
begin
  lblCasa.FontColor := $FFBFBFBF;
  lblRetirada.FontColor := $FFBFBFBF;

  lbl.FontColor := $FFFFFFFF;
  Ind_Entrega := '';
  Ind_Retira := '';

  if lbl.Tag = 0 then
    Ind_Entrega := 'S'
  else
    Ind_Retira := 'S';

  ListarMercados;

  AnimationSelecao.StopValue := lbl.Position.x;
  AnimationSelecao.Start;
end;

procedure TfrmPrincipal.OpenMenu(ind: Boolean);
begin
  if rectMenu.Tag = 0 then
    rectMenu.Visible := True;

  AnimationMenu.StartValue := frmPrincipal.Width + 50;
  AnimationMenu.Start;
end;

procedure TfrmPrincipal.AnimationMenuFinish(Sender: TObject);
begin
  AnimationMenu.Inverse := not AnimationMenu.Inverse;

  if rectMenu.Tag = 1 then
    begin
      rectMenu.Tag := 0;
      rectMenu.Visible := False;
    end
  else
      rectMenu.Tag := 1;
end;

procedure TfrmPrincipal.rectMenuDesconectarClick(Sender: TObject);
begin
  DmUsuarios.Logout;

  if not Assigned(frmLogin) then
    Application.CreateForm(TfrmLogin, frmLogin);


  Application.MainForm := frmLogin;
  frmLogin.Show;
  frmPrincipal.Close;
end;

procedure TfrmPrincipal.rectMenuMeuPerfilClick(Sender: TObject);
begin
  if not Assigned(frmPerfil) then
    Application.CreateForm(TfrmPerfil, frmPerfil);

  OpenMenu(False);
  frmPerfil.Show;
end;

procedure TfrmPrincipal.rectMenuPedidosClick(Sender: TObject);
begin
  if not Assigned(frmPedidos) then
    Application.CreateForm(TfrmPedidos, frmPedidos);

  OpenMenu(False);
  frmPedidos.Show;
end;

procedure TfrmPrincipal.ListViewMercadosItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  if not Assigned(frmMercado) then
    Application.CreateForm(TfrmMercado, frmMercado);

  frmMercado.Id_Mercado := AItem.Tag;
  frmMercado.Show;
end;

procedure TfrmPrincipal.btnBuscarClick(Sender: TObject);
begin
  ListarMercados;
end;

procedure TfrmPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
  frmPrincipal := nil;
end;

procedure TfrmPrincipal.FormShow(Sender: TObject);
begin
  rectMenu.Tag := 0;
  rectMenu.Margins.Right := rectMenu.Width + 50;
  rectMenu.Visible := False;

  SelecionarEntrega(lblCasa);
end;

procedure TfrmPrincipal.imgCarinhoClick(Sender: TObject);
begin
  if not Assigned(frmCarrinho) then
    Application.CreateForm(TfrmCarrinho, frmCarrinho);

  frmCarrinho.Show;
end;

procedure TfrmPrincipal.imgFecharMenuClick(Sender: TObject);
begin
  OpenMenu(False);
end;

procedure TfrmPrincipal.imgMenuClick(Sender: TObject);
begin
  OpenMenu(True);
end;

procedure TfrmPrincipal.lblCasaClick(Sender: TObject);
begin
  SelecionarEntrega(TLabel(Sender));
end;

end.
