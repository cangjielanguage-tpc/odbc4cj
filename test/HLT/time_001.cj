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
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test(data time NOT NULL, datanull time)")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        var date = DateTime.of(
            year: 1970,
            month: 1,
            dayOfMonth: 1,
            hour: 10,
            minute: 10,
            second: 10,
            nanosecond: 0,
        )
        prepareStatement.set<OdbcTypeTime>(0, OdbcTypeTime(date))
        prepareStatement.set<Option<OdbcTypeTime>>(1, Option<OdbcTypeTime>.None)
        // prepareStatement.setNull(1)
        rowCount = prepareStatement.update()
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()

        let a = queryResult.next()
        @Assert(true, a)
        @Assert("SqlOdbcTypeTime", queryResult.columnInfos[0].typeName)
        @Assert("SqlOdbcTypeTime", queryResult.columnInfos[1].typeName)
        @Assert(date, queryResult.get<OdbcTypeTime>(0).value)
        let odbcTypeTime: ?OdbcTypeTime = queryResult.getOrNull<OdbcTypeTime>(1)
        match (odbcTypeTime) {
            case Some(v) => @Assert(0, 1)
            case None => @Assert(1, 1)
        }
        queryResult.close()
    }
}
