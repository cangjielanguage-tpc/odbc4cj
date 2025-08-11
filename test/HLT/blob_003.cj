//3rd_party_lib:odbc4cj/build/odbc4cj

import std.database.sql.*
import std.io.*
import std.time.*
import std.regex.*
import odbc4cj.*

@Test
public class blob_003 {
    var conn: OdbcConnection
    var prepareStatement: OdbcStatement
    var rowCount: OdbcUpdateResult

    init() {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        conn = database.connect()
        prepareStatement = conn.prepareStatement("drop table if exists test")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test(data blob(20) NOT NULL, datanull blob(20))")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
    }

    @TestCase
    public func blob_003(): Unit {
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        var str = ByteBuffer(20)
        let arr: Array<Byte> = [11, 22, 33, 44, 55, 66, 77, 88]
        str.write(arr)
        prepareStatement.set<ByteBuffer>(0, str)
        prepareStatement.set<Option<InputStream>>(1, Option<InputStream>.None)
        rowCount = prepareStatement.update()
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        let a = queryResult.next()
        @Assert(true, a)
        @Assert("SqlInputStream", queryResult.columnInfos[0].typeName)
        @Assert("SqlInputStream", queryResult.columnInfos[1].typeName)
        let inputStream: InputStream = queryResult.get<InputStream>(0)
        var arr1 = Array<UInt8>(arr.size, repeat: 0)
        inputStream.read(arr1)
        @Assert(arr1, arr)
        let inputStream1: ?InputStream = queryResult.getOrNull<InputStream>(1)
        match (inputStream1) {
            case Some(v) => @Assert(0, 1)
            case None => @Assert(1, 1)
        }
        queryResult.close()
    }
}
