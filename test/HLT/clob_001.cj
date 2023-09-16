//3rd_party_lib:odbc4cj/build/odbc4cj

from std import database.sql.*, io.*, time.*, regex.*
from odbc4cj import odbc.*

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
        prepareStatement = conn.prepareStatement("create table test(data text(20) NOT NULL, datanull text(20))")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        var str = ByteArrayStream(20)
        str.write("上了飞机".toUtf8Array())
        rowCount = prepareStatement.update([SqlClob(str), SqlNullableClob(None)])
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        var arr: Array<SqlDbType> = [SqlClob(str), SqlNullableClob(None)]
        queryResult.next(arr)
        @Assert("SqlClob", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlClob =>
                var a = Array<UInt8>(v.value.length, item: 0)
                v.value.read(a)
                @Assert("上了飞机".toUtf8Array().toString(), a.toString())
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableClob", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableClob =>
                match(v.value) {
                    case Some(v) =>
                        var a = Array<UInt8>(v.length, item: 0)
                        v.read(a)
                        @Assert(None<Array<UInt8>>, a)
                    case None => @Assert(None<String>, None<String>)
                }
            case _ => @Assert("abc", "123")
        }
    }
}
