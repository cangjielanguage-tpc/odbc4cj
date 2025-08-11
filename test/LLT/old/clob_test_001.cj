// EXEC: cjc %import-path %L %l %f
// EXEC: ./main


import std.database.sql.* 
import std.io.*
import std.time.*
import std.regex.*
import odbc4cj.*
import std.unittest.*
import std.unittest.testmacro.*

main(): Int64 {
    let filterResultTest: OdbcTest = OdbcTest()

    filterResultTest.test001()

    return 0
}

@Test
public class OdbcTest {
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var prepareStatement = conn.prepareStatement("drop table if exists test_llt")
        var rowCount = prepareStatement.update([])
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test_llt(data text(20) NOT NULL, datanull text(20))")
        rowCount = prepareStatement.update([])
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test_llt values(?,?)")
        var str = ByteBuffer(20)
        str.write("上了飞机".toArray())
        rowCount = prepareStatement.update([SqlClob(str), SqlNullableClob(None)])
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test_llt")
        var queryResult = prepareStatement.query([])
        var arr: Array<SqlDbType> = [SqlClob(str), SqlNullableClob(None)]
        queryResult.next(arr)
        @Assert("SqlClob", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlClob =>
                var a = Array<UInt8>("上了飞机".toArray().size, repeat: 0)
                v.value.read(a)
                @Assert("上了飞机".toArray().toString(), a.toString())
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableClob", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableClob =>
                match(v.value) {
                    case Some(v) =>
                        var a = Array<UInt8>(1, repeat: 0)
                        v.read(a)
                        @Assert(None<Array<UInt8>>, a)
                    case None => @Assert(None<String>, None<String>)
                }
            case _ => @Assert("abc", "123")
        }
        queryResult.close()
    }
}
