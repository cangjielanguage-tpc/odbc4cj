//3rd_party_lib:odbc4cj/build/odbc4cj

import std.database.sql.*
import std.io.*
import std.time.*
import std.regex.*
import odbc4cj.*

let s = "sfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjhsfsagealkgjea;lgjl;gjafhkajhgephkbnakehgteojgdak;jgpoeajbnhekghtjeojgna;ljge;ajgf;eagjh"

@Test
public class OdbcTest {
    init() {
    }
    
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var prepareStatement = conn.prepareStatement("drop table if exists test")
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test(data text(5000) NOT NULL, datanull text(20))")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        var str = ByteBuffer()
        let arr1 = s.toArray()
        str.write(arr1)
        prepareStatement.set<ByteBuffer>(0, str)
        prepareStatement.set<Option<InputStream>>(1, Option<InputStream>.None)
        // prepareStatement.setNull(1)
        rowCount = prepareStatement.update()
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        let a = queryResult.next()
        @Assert(true, a)
        @Assert("SqlClob", queryResult.columnInfos[0].typeName)
        @Assert("SqlClob", queryResult.columnInfos[1].typeName)
        let inputStream: InputStream = queryResult.get<InputStream>(0)
        var arr = Array<UInt8>(arr1.size, repeat: 0)
        inputStream.read(arr)
        @Assert(arr1, arr)
        let inputStream1: ?InputStream = queryResult.getOrNull<InputStream>(1)
        match (inputStream1) {
            case Some(v) => @Assert(0, 1)
            case None => @Assert(1, 1)
        }
        queryResult.close()
    }
}
