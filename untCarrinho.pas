unit untCarrinho;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.ListBox, System.JSON;

type
  TfrmCarrinho = class(TForm)
    LayoutCabecalho: TLayout;
    lblTitle: TLabel;
    imgVoltar: TImage;
    Layout1: TLayout;
    lblNomeMercado: TLabel;
    lblEndMercado: TLabel;
    btnFinalizaPedido: TButton;
    Rectangle1: TRectangle;
    Layout2: TLayout;
    Label2: TLabel;
    lblSubTotal: TLabel;
    Layout3: TLayout;
    Label4: TLabel;
    lblValorTotal: TLabel;
    Layout4: TLayout;
    Label6: TLabel;
    lblTaxaEntrega: TLabel;
    Layout5: TLayout;
    Label8: TLabel;
    lblEndEntrega: TLabel;
    ListBoxProdutosCarinho: TListBox;
    procedure FormShow(Sender: TObject);
    procedure imgVoltarClick(Sender: TObject);
    procedure btnFinalizaPedidoClick(Sender: TObject);
  private
    procedure AddProduto(id_produto: integer; descricao, url_foto: string; qtd, valor_unit: double);
    procedure CarregarCarinho;
    procedure DownloadFoto(lb: TListBox);
    procedure ThreadPedidoTerminate(Sender: TObject);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmCarrinho: TfrmCarrinho;

implementation

{$R *.fmx}

uses untPrincipal, untFrameProdutosLista, untDmMercados, untDmUsuarios,
  untFunctions, uLoading;

procedure TfrmCarrinho.ThreadPedidoTerminate(Sender: TObject);
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

  DmMercados.LimparCarrinhoLocal;
  Close;
end;

procedure TfrmCarrinho.DownloadFoto(lb: TListBox);
var
  t: TThread;
  frame: TfrmFrameProdutosLista;
begin
  // Carregar imagens...
  t := TThread.CreateAnonymousThread(procedure
  var
    i : integer;
  begin
    for i := 0 to lb.Items.Count - 1 do
      begin
        frame := TfrmFrameProdutosLista(lb.ItemByIndex(i).Components[0]);

        if frame.imgProduto.TagString <> '' then
          LoadImageFromURL(frame.imgProduto.Bitmap, frame.imgProduto.TagString);
      end;
  end);

  t.Start;
end;

procedure TfrmCarrinho.AddProduto(id_produto: integer; descricao, url_foto: string; qtd, valor_unit: double);
var
  item: TListBoxItem;
  frame: TfrmFrameProdutosLista;
begin
  item := TListBoxItem.Create(ListBoxProdutosCarinho);
  item.Selectable := False;
  item.Text := '';
  item.Height := 75;
  item.Tag := id_produto;

  //Frame
  frame := TfrmFrameProdutosLista.Create(item);
  frame.imgProduto.TagString := url_foto;
  frame.lblDescricao.Text := descricao;
  frame.lblQtd.Text := qtd.ToString + ' x ' + FormatFloat('R$ #,##0.00', valor_unit);
  frame.lblPreco.Text := FormatFloat('R$ #,##0.00', qtd * valor_unit);

  item.AddObject(frame);
  ListBoxProdutosCarinho.AddObject(item);
end;

procedure TfrmCarrinho.btnFinalizaPedidoClick(Sender: TObject);
var
  t: TThread;
  jsonPedido: TJSONObject;
  arrayItem: TJSONArray;
begin
  TLoading.Show(frmCarrinho, '');

  t := TThread.CreateAnonymousThread(procedure
    begin
      try
        jsonPedido := DmMercados.JsonPedido(lblSubTotal.TagFloat, lblTaxaEntrega.TagFloat, lblValorTotal.TagFloat);
        jsonPedido.AddPair('itens', DmMercados.ArrayPedidoItem);

        DmMercados.InserirPedido(jsonPedido);
      finally
        jsonPedido.DisposeOf;
      end;

    end);

  t.OnTerminate := ThreadPedidoTerminate;
  t.Start;
end;

procedure TfrmCarrinho.CarregarCarinho;
var
  SubTotal: Double;
begin
  ListBoxProdutosCarinho.Items.Clear;

  try
    DmMercados.ListarCarrinhoLocal;
    DmMercados.ListarItemCarrinhoLocal;
    DmUsuarios.ListarUsuarioLocal;

    //Dados Mercado
    with DmMercados.FDQryCarrinho do
      begin
        lblNomeMercado.Text := FieldByName('NOME_MERCADO').Value;
        lblEndMercado.Text := FieldByName('ENDERECO_MERCADO').Value;
        lblTaxaEntrega.Text := FormatFloat('R$ #,##0.00', FieldByName('TAXA_ENTREGA').AsFloat);
        lblTaxaEntrega.TagFloat := FieldByName('TAXA_ENTREGA').AsFloat;
      end;

    //Dados Usuario
    lblEndEntrega.Text := DmUsuarios.FDQryUsuario.FieldByName('ENDERECO').Value;

    //Itens do Carrinho
    SubTotal := 0;
    with DmMercados.FDQryCarrinhoItem do
      begin
        while not EOF do
          begin
            AddProduto(FieldByName('ID_PRODUTO').AsInteger,
                       FieldByName('NOME').AsString,
                       FieldByName('URL_FOTO').AsString,
                       FieldByName('QTD').AsFloat,
                       FieldByName('VALOR_UNITARIO').AsFloat);

            SubTotal := SubTotal + FieldByName('VALOR_TOTAL').AsFloat;

            Next;
          end;
      end;

    lblSubTotal.Text := FormatFloat('R$ #,##0.00', SubTotal);
    lblSubTotal.TagFloat := SubTotal;
    lblValorTotal.Text := FormatFloat('R$ #,##0.00', SubTotal + lblTaxaEntrega.TagFloat);
    lblValorTotal.TagFloat := SubTotal + lblTaxaEntrega.TagFloat;

    //Carrega as fotos
    DownloadFoto(ListBoxProdutosCarinho);

  except on ex:Exception do
    ShowMessage('Erro ao carregar carrinho: ' + ex.Message);
  end;
end;

procedure TfrmCarrinho.FormShow(Sender: TObject);
begin
  CarregarCarinho;
end;

procedure TfrmCarrinho.imgVoltarClick(Sender: TObject);
begin
  close;
end;

end.

