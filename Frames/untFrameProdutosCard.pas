unit untFrameProdutosCard;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation;

type
  TfrmFrameProdutoCard = class(TFrame)
    lblDescricao: TLabel;
    lblPreco: TLabel;
    lblUnidade: TLabel;
    imgProduto: TImage;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

end.