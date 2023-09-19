unit untProduto;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls, untFunctions,
  uLoading, System.Net.HttpClientComponent, System.Net.HttpClient, FMX.DialogService;

type
  TfrmProduto = class(TForm)
    LayoutCabecalho: TLayout;
    lblTitle: TLabel;
    imgVoltar: TImage;
    imgProd: TImage;
    LayoutImgProd: TLayout;
    lblNome: TLabel;
    Layout1: TLayout;
    Layout2: TLayout;
    lblPreco: TLabel;
    lblUnidade: TLabel;
    lblDescricao: TLabel;
    RectRodape: TRectangle;
    Layout3: TLayout;
    imgMenos: TImage;
    imgMais: TImage;
    lblQtd: TLabel;
    btnAdd: TButton;
    procedure imgVoltarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure imgMaisClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
  private
    FId_Produto: integer;
    FId_Mercado: integer;
    FNome_Mercado: string;
    FTaxa_Entrega: double;
    FEndereco_Mercado: string;
    procedure CarregarDados;
    procedure ThreadDadosTerminate(Sender: TObject);
    procedure Qtd(valor: integer);
    { Private declarations }
  public
    { Public declarations }
    property Id_Produto: integer read FId_Produto write FId_Produto;
    property Id_Mercado: integer read FId_Mercado write FId_Mercado;
    property Nome_Mercado: string read FNome_Mercado write FNome_Mercado;
    property Endereco_Mercado: string read FEndereco_Mercado write FEndereco_Mercado;
    property Taxa_Entrega: double read FTaxa_Entrega write FTaxa_Entrega;
  end;

var
  frmProduto: TfrmProduto;

implementation

{$R *.fmx}

uses untPrincipal, untDmMercados;

procedure TfrmProduto.Qtd(valor: integer);
begin
  try
    if valor = 0 then
      lblQtd.Tag := 1
    else
      lblQtd.Tag := lblQtd.Tag + valor;

    if lblQtd.Tag <= 0 then
      lblQtd.Tag := 1;
  finally

  end;

  lblQtd.Text := FormatFloat('00', lblQtd.Tag)
end;

procedure TfrmProduto.ThreadDadosTerminate(Sender: TObject);
begin
  TLoading.Hide;
  lblNome.Opacity := 1;
  lblPreco.Opacity := 1;
  lblUnidade.Opacity := 1;
  lblDescricao.Opacity := 1;
  imgProd.Opacity := 1;

  if Sender is TThread then
    begin
        if Assigned(TThread(Sender).FatalException) then
          begin
            ShowMessage(Exception(TThread(Sender).FatalException).Message);
            Exit;
          end;
    end;
end;

procedure TfrmProduto.btnAddClick(Sender: TObject);
begin
  if DmMercados.ExistePedidoLocal(Id_Mercado) then
    begin
      TDialogService.MessageDialog('Você só pode adicionar itens de um mercado por vez. Deseja esvaziar a sacola' +
      ' e adicionar esse item?',
      TMsgDlgType.mtConfirmation,
      [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
      TMsgDlgBtn.mbNo,
      0,
      procedure(const AResult: TModalResult)
        begin
          if AResult = mrYes then
            begin
              DmMercados.LimparCarrinhoLocal;
              DmMercados.AdicionarCarrinhoLocal(Id_Mercado, Nome_Mercado, Endereco_Mercado,
                                          Taxa_Entrega);
              DmMercados.AdicionarItemCarrinhoLocal(Id_Produto, imgProd.TagString,
                                              lblNome.Text, lblUnidade.Text, lblQtd.Tag,
                                              lblPreco.TagFloat);
            end;
        end);
    end
  else
    begin
      DmMercados.AdicionarCarrinhoLocal(Id_Mercado, Nome_Mercado, Endereco_Mercado,
                                  Taxa_Entrega);
      DmMercados.AdicionarItemCarrinhoLocal(Id_Produto, imgProd.TagString,
                                      lblNome.Text, lblUnidade.Text, lblQtd.Tag,
                                      lblPreco.TagFloat);
    end;

  Close;
end;

procedure TfrmProduto.CarregarDados;
var
  t: TThread;
begin
  Qtd(0);
  TLoading.Show(frmProduto, '');
  lblNome.Opacity := 0;
  lblPreco.Opacity := 0;
  lblUnidade.Opacity := 0;
  lblDescricao.Opacity := 0;
  imgProd.Opacity := 0;


  t := TThread.CreateAnonymousThread(procedure
  begin
    DmMercados.ListarProdutosId(Id_Produto);

    with DmMercados.TabDetalheProd do
      begin
        TThread.Synchronize(TThread.CurrentThread, procedure
          begin
            lblNome.Text := FieldByName('nome').AsString;
            lblDescricao.Text := FieldByName('descricao').AsString;
            lblUnidade.Text := FieldByName('unidade').AsString;
            lblPreco.Text := FormatFloat('R$#,##0.00', FieldByName('preco').AsFloat);
            lblPreco.TagFloat := FieldByName('preco').AsFloat;
          end);

        imgProd.TagString := FieldByName('url_foto').AsString;
        LoadImageFromURL(imgProd.Bitmap, FieldByName('url_foto').AsString);
      end;
  end);

  t.OnTerminate := ThreadDadosTerminate;
  t.Start;
end;

procedure TfrmProduto.FormShow(Sender: TObject);
begin
  CarregarDados;
end;

procedure TfrmProduto.imgMaisClick(Sender: TObject);
begin
  Qtd(TImage(Sender).Tag)
end;

procedure TfrmProduto.imgVoltarClick(Sender: TObject);
begin
  close;
end;

end.
