//3rd_party_lib:odbc4cj/build/odbc4cj

from std import database.sql.*, io.*, time.*, regex.*
from odbc4cj import odbc.*

@Test
public class blob_001 {
    var conn: OdbcConnection
    var prepareStatement: OdbcStatement
    var rowCount: OdbcUpdateResult
    init(){
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
    public func blob_001(): Unit {
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        var str = ByteArrayStream(20)
        str.write([11,22,33])
        rowCount = prepareStatement.update([SqlBlob(str), SqlNullableBlob(None)])
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        var arr: Array<SqlDbType> = [SqlBlob(str), SqlNullableBlob(None)]
        queryResult.next(arr)
        @Assert("SqlBlob", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlBlob =>
                var a = Array<UInt8>(3, item: 0)
                v.value.read(a)
                @Assert([11,22,33].toString(), a.toString())
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableBlob", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableBlob =>
                match(v.value) {
                    case Some(v) =>
                        var a = Array<UInt8>(1, item: 0)
                        v.read(a)
                        @Assert(None<Array<UInt8>>, a)
                    case None => @Assert(None<String>, None<String>)
                }
            case _ => @Assert("abc", "123")
        }
    }
}
