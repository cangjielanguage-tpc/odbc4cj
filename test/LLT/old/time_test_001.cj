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
        prepareStatement = conn.prepareStatement("create table test_llt(data time NOT NULL, datanull time)")
        rowCount = prepareStatement.update([])
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test_llt values(?,?)")
        var date = DateTime.of(
            year: 1970,
            month: 1,
            dayOfMonth: 1,
            hour: 10,
            minute: 10,
            second: 10,
            nanosecond: 0,
        )
        rowCount = prepareStatement.update([SqlTime(date), SqlNullableTime(None)])
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test_llt")
        var queryResult = prepareStatement.query([])
        var arr: Array<SqlDbType> = [SqlTime(date), SqlNullableTime(None)]
        queryResult.next(arr)
        @Assert("SqlTime", queryResult.columnInfos[0].typeName)
        match (arr[0]) {
            case v: SqlTime => @Assert(date, v.value)
            case _ => @Assert("abc", "123")
        }
        @Assert("SqlNullableTime", queryResult.columnInfos[1].typeName)
        match (arr[1]) {
            case v: SqlNullableTime => @Assert(None, v.value)
            case _ => @Assert("abc", "123")
        }
        queryResult.close()
    }
}
