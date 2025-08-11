//3rd_party_lib:odbc4cj/build/odbc4cj

import std.database.sql.* 
import std.io.*
import std.time.*
import std.regex.*
import std.math.*
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
        prepareStatement = conn.prepareStatement("create table test(data SmallInt NOT NULL, datanull SmallInt)")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        prepareStatement.set<Int16>(0, Int16.Max)
        prepareStatement.set<Option<Int16>>(1, Option<Int16>.None)
        // prepareStatement.setNull(1)
        rowCount = prepareStatement.update()
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        let a = queryResult.next()
        @Assert(true, a)
        @Assert("SqlInt16", queryResult.columnInfos[0].typeName)
        @Assert("SqlInt16", queryResult.columnInfos[1].typeName)
        @Assert(Int16.Max, queryResult.get<Int16>(0))
        @Assert(None, queryResult.getOrNull<Int16>(1))
        queryResult.close()
    }
}
