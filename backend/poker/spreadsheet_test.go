package poker

import (
    "archive/zip"
    "encoding/xml"
    "fmt"
    "io"
    "strings"
    "testing"
)

// minimal structs for sheet XML parsing

type cell struct {
    T string `xml:"t,attr"` // type
    V string `xml:"v"`
}

type row struct {
    Cells []cell `xml:"c"`
}

type sheetData struct {
    Rows []row `xml:"row"`
}

type sheet struct {
    Data sheetData `xml:"sheetData"`
}

// TestSpreadsheet reads the first worksheet of the provided XLSX file
// without any external libraries, then logs each row's cell values.  This
// makes it easy to verify that the spreadsheet's cases match expectations.
func TestSpreadsheet(t *testing.T) {
    // package is backend/poker so move two levels up to workspace root
    fpath := "../../Texas HoldEm Hand comparison test cases.xlsx"
    zr, err := zip.OpenReader(fpath)
    if err != nil {
        t.Fatalf("unable to open xlsx: %v", err)
    }
    defer zr.Close()

    var shared []string
    var sht sheet

    // helper to read XML file into target
    decode := func(name string, v interface{}) error {
        for _, f := range zr.File {
            if strings.EqualFold(f.Name, name) {
                rc, err := f.Open()
                if err != nil {
                    return err
                }
                defer rc.Close()
                return xml.NewDecoder(rc).Decode(v)
            }
        }
        return io.EOF
    }

    // load sharedStrings (if present)
    _ = decode("xl/sharedStrings.xml", &struct {
        SI []struct {
            T string `xml:"t"`
        } `xml:"si"`
    }{ /* we don't need */ })
    // simpler: we ignore shared strings for now as cards appear literal

    if err := decode("xl/worksheets/sheet1.xml", &sht); err != nil {
        t.Fatalf("failed to decode sheet: %v", err)
    }

    for i, r := range sht.Data.Rows {
        vals := make([]string, len(r.Cells))
        for j, c := range r.Cells {
            if c.T == "s" {
                // index into shared strings
                idx := 0
                fmt.Sscanf(c.V, "%d", &idx)
                if idx < len(shared) {
                    vals[j] = shared[idx]
                } else {
                    vals[j] = "" // out of range
                }
            } else {
                vals[j] = c.V
            }
        }
        t.Logf("row %d: %v", i+1, vals)
    }
}
