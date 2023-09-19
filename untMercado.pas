unit untMercado;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.ListBox,
  uLoading, System.Net.HttpClientComponent, System.Net.HttpClient, untFunctions;

type
  TfrmMercado = class(TForm)
    LayoutCabecalho: TLayout;
    lblTitle: TLabel;
    imgVoltar: TImage;
    imgCarrinho: TImage;
    LayoutPesquisa: TLayout;
    RectPesquisar: TRectangle;
    edtBuscaProduto: TEdit;
    Image3: TImage;
    btnBuscar: TButton;
    LayoutDadosMercado: TLayout;
    lblEnd: TLabel;
    Image4: TImage;
    Image5: TImage;
    lblTaxa: TLabel;
    lblCompraMin: TLabel;
    ListBoxCategoria: TListBox;
    ListBoxItem1: TListBoxItem;
    Rectangle1: TRectangle;
    Label1: TLabel;
    ListBoxItem2: TListBoxItem;
    Rectangle2: TRectangle;
    Label2: TLabel;
    ListBoxProdutos: TListBox;
    procedure FormShow(Sender: TObject);
    procedure ListBoxCategoriaItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure ListBoxProdutosItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure imgCarrinhoClick(Sender: TObject);
    procedure btnBuscarClick(Sender: TObject);
    procedure imgVoltarClick(Sender: TObject);
  private
    FId_Mercado: integer;
    procedure AddProduto(id_produto: integer; descricao, unidade, url_foto: string; valor: double);
    procedure ListarProdutos(id_categoria: integer; busca: string);
    procedure ListarCategorias;
    procedure AddCategoria(id_categoria: integer; descricao: string);
    procedure SelecionaCategoria(item: TListBoxItem);
    procedure CarregarDados;
    procedure ThreadDadosTerminate(Sender: TObject);
    procedure ThreadProdutosTerminate(Sender: TObject);
    procedure DownloadFoto(lb: TListBox);
    { Private declarations }
  public
    { Public declarations }
    property Id_Mercado: integer read FId_Mercado write FId_Mercado;
  end;

var
  frmMercado: TfrmMercado;

implementation

{$R *.fmx}

uses untPrincipal, untFrameProdutosCard, untProduto, untCarrinho, untDmMercados;

procedure TfrmMercado.DownloadFoto(lb: TListBox);
var
  t: TThread;
  foto: TBitmap;
  frame: TfrmFrameProdutoCard;
begin
  // Carregar imagens...
  t := TThread.CreateAnonymousThread(procedure
  var
    i : integer;
  begin
    for i := 0 to lb.Items.Count - 1 do
      begin
        frame := TfrmFrameProdutoCard(lb.ItemByIndex(i).Components[0]);

        if frame.imgProduto.TagString <> '' then
          begin
            foto := TBitmap.Create;
            LoadImageFromURL(foto, frame.imgProduto.TagString);

            frame.imgProduto.TagString := '';
            frame.imgProduto.bitmap := foto;
          end;
      end;
  end);

  t.Start;
end;

procedure TfrmMercado.ThreadDadosTerminate(Sender: TObject);
begin
  TLoading.Hide;
  lblTitle.Opacity := 1;
  LayoutDadosMercado.Opacity := 1;
  ListBoxProdutos.Opacity := 1;

  if Sender is TThread then
    begin
        if Assigned(TThread(Sender).FatalException) then
          begin
            ShowMessage(Exception(TThread(Sender).FatalException).Message);
            Exit;
          end;
    end;

  ListarProdutos(ListBoxCategoria.Tag, edtBuscaProduto.Text);
end;

procedure TfrmMercado.ThreadProdutosTerminate(Sender: TObject);
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

    DownloadFoto(ListBoxProdutos);
end;

procedure TfrmMercado.CarregarDados;
var
  t: TThread;
begin
  TLoading.Show(frmMercado, '');
  ListBoxCategoria.Items.Clear;
  ListBoxProdutos.Items.Clear;
  lblTitle.Opacity := 0;
  LayoutDadosMercado.Opacity := 0;
  ListBoxProdutos.Opacity := 0;

  //ListBoxCategoria.Items.Clear;
  //ListViewMercados.BeginUpdate;

  t := TThread.CreateAnonymousThread(procedure
  begin
    DmMercados.ListarMercadoId(Id_Mercado);

    with DmMercados.TabMercado do
      begin
        TThread.Synchronize(TThread.CurrentThread, procedure
          begin
            lblTitle.Text := FieldByName('nome').AsString;
            lblEnd.Text := FieldByName('endereco').AsString;
            lblTaxa.Text := 'Tx. Entreg: ' + FormatFloat('R$#,##0.00', FieldByName('vl_entrega').AsFloat);
            lblTaxa.TagFloat := FieldByName('vl_entrega').AsFloat;
            lblCompraMin.Text :=  'Compra Mín: ' + FormatFloat('R$#,##0.00', FieldByName('vl_compra_min').AsFloat);
          end);
      end;

      ListarCategorias;
  end);

  t.OnTerminate := ThreadDadosTerminate;
  t.Start;
end;

procedure TfrmMercado.ListarCategorias;
var
  i: integer;
begin
  DmMercados.ListarCategoria(Id_Mercado);

  with DmMercados.TabCategoria do
    begin
      for i := 0 to RecordCount - 1 do
        begin
          TThread.Synchronize(TThread.CurrentThread, procedure
            begin
              AddCategoria(FieldByName('id_categoria').AsInteger, FieldByName('descricao').AsString);
            end);

          Next;
        end;
    end;

  if ListBoxCategoria.Items.Count > 0 then
    TThread.Synchronize(TThread.CurrentThread, procedure
      begin
        SelecionaCategoria(ListBoxCategoria.ItemByIndex(0));
      end);
end;

procedure TfrmMercado.AddCategoria(id_categoria: integer; descricao: string);
var
  item: TListBoxItem;
  rect: TRectangle;
  lbl: TLabel;
begin
  item := TListBoxItem.Create(ListBoxCategoria);
  item.Selectable := False;
  item.Text := '';
  item.Width := 125;
  item.Tag := id_categoria;

  rect := TRectangle.Create(item);
  rect.Align := TAlignLayout.Client;
  rect.Cursor := crHandPoint;
  rect.Fill.Color := $FFE2E2E2;
  rect.HitTest := False;
  rect.Margins.Top := 10;
  rect.Margins.Left := 10;
  rect.Margins.Right := 10;
  rect.Margins.Bottom := 10;
  rect.Stroke.Kind := TBrushKind.None;
  rect.XRadius := 5;
  rect.YRadius := 5;

  lbl := TLabel.Create(rect);
  lbl.Align := TAlignLayout.Client;
  lbl.Text := descricao;
  lbl.TextSettings.HorzAlign := TTextAlign.Center;
  lbl.TextSettings.VertAlign := TTextAlign.Center;
  lbl.StyledSettings := lbl.StyledSettings - [TStyledSetting.Size, TStyledSetting.FontColor, TStyledSetting.Style, TStyledSetting.Other];
  lbl.Font.Size := 14;
  lbl.FontColor := $FF3A3A3A;

  rect.AddObject(lbl);
  item.AddObject(rect);
  ListBoxCategoria.AddObject(item);
end;

procedure TfrmMercado.SelecionaCategoria(item: TListBoxItem);
var
  x: Integer;
  item_loop: TListBoxItem;
  rect: TRectangle;
  lbl: TLabel;
begin
  for x := 0 to ListBoxCategoria.Items.Count - 1 do
    begin
      item_loop := ListBoxCategoria.ItemByIndex(x);

      rect := TRectangle(item_loop.Components[0]);
      rect.Fill.Color := $FFE2E2E2;

      lbl := TLabel(rect.Components[0]);
      lbl.FontColor := $FF3A3A3A;
    end;

  rect := TRectangle(item.Components[0]);
  rect.Fill.Color := $FF64BA01;

  lbl := TLabel(rect.Components[0]);
  lbl.FontColor := $FFFFFFFF;

  ListBoxCategoria.Tag := item.Tag;
end;

procedure TfrmMercado.ListarProdutos(id_categoria: integer; busca: string);
var
  t: TThread;
begin
  ListBoxProdutos.Items.Clear;
  TLoading.Show(frmMercado, '');

  t := TThread.CreateAnonymousThread(procedure
  var
    i: Integer;
  begin
    DmMercados.ListarProdutos(Id_Mercado, id_categoria, edtBuscaProduto.Text);

    with DmMercados.TabProduto do
      begin
        for i := 0 to RecordCount - 1 do
          begin
            TThread.Synchronize(TThread.CurrentThread, procedure
              begin
                AddProduto(FieldByName('id_produto').AsInteger,
                          FieldByName('nome').AsString,
                          FieldByName('unidade').AsString,
                          FieldByName('url_foto').AsString,
                          FieldByName('preco').AsFloat);
              end);

            Next;
          end;
      end;
  end);

  t.OnTerminate := ThreadProdutosTerminate;
  t.Start;
end;

procedure TfrmMercado.AddProduto(id_produto: integer; descricao, unidade, url_foto: string; valor: double);
var
  item: TListBoxItem;
  frame: TfrmFrameProdutoCard;
begin
  item := TListBoxItem.Create(ListBoxProdutos);
  item.Selectable := False;
  item.Text := '';
  item.Height := 200;
  item.Tag := id_produto;

  //Frame
  frame := TfrmFrameProdutoCard.Create(item);
  //frame.imgProduto.Bitmap :=
  frame.lblDescricao.Text := descricao;
  frame.lblPreco.Text := FormatFloat('R$ #,##0.00', valor);
  frame.lblUnidade.Text := unidade;
  frame.imgProduto.TagString := url_foto;

  item.AddObject(frame);
  ListBoxProdutos.AddObject(item);
end;

procedure TfrmMercado.btnBuscarClick(Sender: TObject);
begin
  ListarProdutos(ListBoxCategoria.Tag, edtBuscaProduto.Text);
end;

procedure TfrmMercado.ListBoxCategoriaItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
begin
  SelecionaCategoria(Item);
  ListarProdutos(ListBoxCategoria.Tag, edtBuscaProduto.Text);
end;

procedure TfrmMercado.ListBoxProdutosItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
begin
  if not Assigned(frmProduto) then
    Application.CreateForm(TfrmProduto, frmProduto);

  frmProduto.Id_Mercado := frmMercado.Id_Mercado;
  frmProduto.Nome_Mercado := lblTitle.Text;
  frmProduto.Endereco_Mercado := lblEnd.Text;
  frmProduto.Taxa_Entrega := lblTaxa.TagFloat;

  frmProduto.Id_Produto := Item.Tag;
  frmProduto.Show;
end;

procedure TfrmMercado.FormShow(Sender: TObject);
begin
  edtBuscaProduto.Text := '';
  CarregarDados;
end;

procedure TfrmMercado.imgCarrinhoClick(Sender: TObject);
begin
  if not Assigned(frmCarrinho) then
    Application.CreateForm(TfrmCarrinho, frmCarrinho);

  frmCarrinho.Show;
end;

procedure TfrmMercado.imgVoltarClick(Sender: TObject);
begin
  close;
end;

end.
