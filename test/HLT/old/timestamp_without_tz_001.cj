//3rd_party_lib:odbc4cj/build/odbc4cj

import std.database.sql.* 
import std.io.*
import std.time.*
import std.regex.*
import odbc4cj.*

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
        var rowCount = prepareStatement.update([])
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test(data TIMESTAMP NOT NULL, datanull TIMESTAMP)")
        rowCount = prepareStatement.update([])
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        var date = DateTime.of(
            year: 2009,
            month: 11,
            dayOfMonth: 21,
            hour: 13,
            minute: 15,
            second: 35,
            nanosecond: 0,
        )
        rowCount = prepareStatement.update([SqlTimestampWithoutTz(date), SqlNullableTimestampWithoutTz(None)])
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query([])
        var arr: Array<SqlDbType> = [SqlTimestampWithoutTz(DateTime.now()), SqlNullableTimestampWithoutTz(None)]
        queryResult.next(arr)
        match (arr[0]) {
            case v: SqlTimestampWithoutTz => @Assert(date, v.value)
            case _ => @Assert("abc", "123")
        }
        match (arr[1]) {
            case v: SqlNullableTimestampWithoutTz => @Assert(None, v.value)
            case _ => @Assert("abc", "123")
        }
        queryResult.close()
    }
}
