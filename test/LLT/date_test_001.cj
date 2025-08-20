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
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test_llt(data date NOT NULL, datanull date)")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test_llt values(?,?)")
        var date = DateTime.of(
            year: 2023,
            month: 7,
            dayOfMonth: 20,
            hour: 0,
            minute: 0,
            second: 0,
            nanosecond: 0,
        )
        prepareStatement.set<OdbcTypeDate>(0, OdbcTypeDate(date))
        prepareStatement.set<Option<OdbcTypeDate>>(1, Option<OdbcTypeDate>.None)
        // prepareStatement.setNull(1)
        rowCount = prepareStatement.update()
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test_llt")
        var queryResult = prepareStatement.query()
        let a = queryResult.next()
        @Assert(true, a)
        @Assert("SqlOdbcTypeDate", queryResult.columnInfos[0].typeName)
        @Assert("SqlOdbcTypeDate", queryResult.columnInfos[1].typeName)
        @Assert(date, queryResult.get<OdbcTypeDate>(0).value)
        let odbcTypeDate: ?OdbcTypeDate = queryResult.getOrNull<OdbcTypeDate>(1)
        match (odbcTypeDate) {
            case Some(v) => @Assert(0, 1)
            case None => @Assert(1, 1)
        }
        queryResult.close()
    }
}
